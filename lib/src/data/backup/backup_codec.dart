import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class BackupCodecException implements Exception {
  const BackupCodecException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BackupCodec {
  BackupCodec({Random? random}) : _random = random ?? Random.secure();

  static const format = 'lucentvisit-encrypted-backup';
  static const version = 2;
  static const iterations = 600000;
  static const maxPlaintextBytes = 10 * 1024 * 1024;
  static const maxBackupBytes = 15 * 1024 * 1024;
  static const _aad = 'lucentvisit-encrypted-backup:v2';

  final Random _random;
  final Cipher _cipher = AesGcm.with256bits();

  Future<Uint8List> encode({
    required Map<String, Object?> payload,
    required String password,
  }) async {
    _validatePassword(password);
    final plaintext = utf8.encode(jsonEncode(payload));
    if (plaintext.length > maxPlaintextBytes) {
      throw const BackupCodecException('The backup is too large.');
    }

    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final key = await _deriveKey(password, salt);
    final box = await _cipher.encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
      aad: utf8.encode(_aad),
    );
    final envelope = <String, Object?>{
      'format': format,
      'version': version,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'kdf': 'pbkdf2-hmac-sha256',
      'iterations': iterations,
      'cipher': 'aes-256-gcm',
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
    final encoded = Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
    if (encoded.length > maxBackupBytes) {
      throw const BackupCodecException('The backup is too large.');
    }
    return encoded;
  }

  Future<DecodedBackup> decode({
    required Uint8List bytes,
    required String password,
  }) async {
    _validatePassword(password);
    if (bytes.isEmpty || bytes.length > maxBackupBytes) {
      throw const BackupCodecException(
        'The backup file is invalid or too large.',
      );
    }

    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) throw const FormatException();
      final envelope = decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      if (envelope['format'] != format ||
          envelope['version'] != version ||
          envelope['kdf'] != 'pbkdf2-hmac-sha256' ||
          envelope['iterations'] != iterations ||
          envelope['cipher'] != 'aes-256-gcm') {
        throw const BackupCodecException(
          'This backup format is not supported.',
        );
      }

      final createdAt = DateTime.parse(_string(envelope, 'created_at')).toUtc();
      final salt = base64Decode(_string(envelope, 'salt'));
      final nonce = base64Decode(_string(envelope, 'nonce'));
      final cipherText = base64Decode(_string(envelope, 'ciphertext'));
      final mac = base64Decode(_string(envelope, 'mac'));
      if (salt.length != 16 || nonce.length != 12 || mac.length != 16) {
        throw const FormatException();
      }
      final key = await _deriveKey(password, salt);
      final plaintext = await _cipher.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
        aad: utf8.encode(_aad),
      );
      if (plaintext.length > maxPlaintextBytes) throw const FormatException();
      final payload = jsonDecode(utf8.decode(plaintext));
      if (payload is! Map) throw const FormatException();
      return DecodedBackup(
        createdAt: createdAt,
        payload: payload.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on BackupCodecException {
      rethrow;
    } on SecretBoxAuthenticationError {
      throw const BackupCodecException(
        'Wrong password or the backup file is corrupted.',
      );
    } on Object {
      throw const BackupCodecException(
        'The backup file is invalid or corrupted.',
      );
    }
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) => Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);

  Uint8List _randomBytes(int length) => Uint8List.fromList(
    List<int>.generate(length, (_) => _random.nextInt(256)),
  );

  static String _string(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String || value.isEmpty) throw const FormatException();
    return value;
  }

  static void _validatePassword(String password) {
    if (password.length < 12) {
      throw const BackupCodecException(
        'Use a backup password with at least 12 characters.',
      );
    }
  }
}

class DecodedBackup {
  const DecodedBackup({required this.createdAt, required this.payload});
  final DateTime createdAt;
  final Map<String, Object?> payload;
}
