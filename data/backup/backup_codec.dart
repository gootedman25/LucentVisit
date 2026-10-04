import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/helpers.dart';

enum BackupCodecError {
    weakPassword,
    invalidFormat,
    unsupportedVersion,
    authenticationFailed,
    tooLarge,
}

class BackupCodecExemption implements Exception {
    const BackupCodecExemption({
        required this.type,
        required this.message,
    });

    final BackupCodecError type;
    final String message;

    @override
    String toString () => message;
}

class BackupCodec {
    BackupCodec({
        Cipher? cipher,
        Pbkdf2? keyDerivation,
    }) : _cipher = cipher ?? AesGcm.with256bits(),
         _keyDerivation = keyDerivation ?? Pbkdf2(
            iterations: kPbkdf2Iterations,
            bits: 256,
        );

    static const String formatName = 'lucentvisit-backup';
    static const int formatVersion = 2;
    static const int kPbkdf2Iterations = 600000;

    static const int minimumPasswordLength = 12;
    static const int saltLength = 16;

    static const int maximumPlaintextBytes = 10 * 1024 * 1024;
    static const int maximumBackupBytes = 15 * 1024 * 1024;

    static final List<int> _authenicatedMetadata = utf8.encode(
        '$formatName|$formatVersion|'
        'pbkdf2-hmac-sha256|$kPbkdf2Iterations|aes-256-gcm',
    );

    final Cipher _cipher;
    final Pbkdf2 _keyDerivation;

    Future <Uint8List> encrypt({
        required Map<String, dynamic> payload,
        required String password,
    }) async {
        _validateNewPassword(password);
    
        final plaintext = utf8.encode(jsonEncode(payload));

        if (plaintext.length > maximumPlaintextBytes) {
            throw BackupCodecExemption(
                type: BackupCodecError.tooLarge,
                message: 'The plaintext is too large to encrypt.',
            );
        }

        final salt = randomBytes(saltLength);
        final nonce = _cipher.newNonce();
        final secretKey = await _keyDerivation.deriveKeyFromPassword(
            password: password,
            nonce: salt,
        );

        try{ 
            final secretBox = await _cipher.encrypt(
                plaintext,
                secretKey: secretKey,
                nonce: nonce,
                aad: _authenicatedMetadata,
            );

            final envelope = <String, dynamic>{
                'format': formatName,
                'version': formatVersion,
                'kdf': {
                    'name': 'pbkdf2-hmac-sha256',
                    'iterations': kPbkdf2Iterations,
                    'salt': base64.encode(salt),
                },
                'cipher': {
                    'name': 'aes-256-gcm',
                    'nonce': base64Encode(secretBox.nonce),
                    'ciphertext': base64Encode(secretBox.cipherText),
                    'mac': base64Encode(secretBox.mac.bytes),
                },
            };

            final encoded = Uint8List.fromList(
                utf8.encode(jsonEncode(envelope)),
            );

            if (encoded.length > maximumBackupBytes) {
                throw BackupCodecExemption(
                    type: BackupCodecError.tooLarge,
                    message: 'The backup is too large to encrypt.',
                );
            }

            return encoded;
            } finally {
                secretKey.destroy();
            }
        }

    Future<Map<String, dynamic>> decrypt({
        required List<int> backupBytes,
        required String password,
        }) async {
        if (password.isEmpty) {
        throw const BackupCodecException(
            type: BackupCodecErrorType.authenticationFailed,
            message: 'Enter the password used to create this backup.',
        );
        }

        if (backupBytes.isEmpty ||
            backupBytes.length > maximumBackupBytes) {
            throw const BackupCodecException(
                type: BackupCodecErrorType.tooLarge,
                message: 'The selected backup file is empty or too large.',
            );
        }

        final envelope = _decodeEnvelope(backupBytes);
        final kdf = _requiredMap(envelope, 'kdf');
        final cipherData = _requiredMap(envelope, 'cipher');

        if (_requiredString(kdf, 'name') != 'pbkdf2-hmac-sha256' || _requiredInt(kdf, 'iterations') != kPbkdf2Iterations || _requiredString(cipherData, 'name') != 'aes-256-gcm') {
            throw const BackupCodecException(
                type: BackupCodecErrorType.unsupportedVersion,
                message:'This backup uses an unsupported encryption format.',
                );
        }

        final salt = _decodeBase64(kdf, 'salt');
        final nonce = _decodeBase64(cipherData, 'nonce');
        final ciphertext = _decodeBase64(cipherData,'ciphertext',);
        final macBytes = _decodeBase64(cipherData, 'mac');

        if (salt.length != saltLength ||
            nonce.length != _cipher.nonceLength ||
            macBytes.length != 16) {
            throw const BackupCodecException(
            type: BackupCodecErrorType.invalidFormat,
            message: 'The backup file is damaged or invalid.',
            );
        }

        final secretKey = await _keyDerivation.deriveKeyFromPassword(
                password: password,
                nonce: salt,
            );

            try {
            final clearBytes = await _cipher.decrypt(SecretBox(
                ciphertext,
                nonce: nonce,
                mac: Mac(macBytes),),
                secretKey: secretKey,
                aad: _authenticatedMetadata,
            );

            if (clearBytes.length > maximumPlaintextBytes) {
                throw const BackupCodecException(
                type: BackupCodecErrorType.tooLarge,
                message: 'The decrypted backup is too large.',
                );
            }

            final decoded = jsonDecode(utf8.decode(clearBytes),);

            if (decoded is! Map<String, dynamic>) {
                throw const BackupCodecException(
                type: BackupCodecErrorType.invalidFormat,
                message: 'The backup contents are invalid.',
                );
            }

            return decoded;
        } on SecretBoxAuthenticationError {
      // Deliberately do not reveal whether the password or file was wrong.
        throw const BackupCodecException(
            type: BackupCodecErrorType.authenticationFailed,
            message:'The password is incorrect or the backup file is damaged.',
        );
        } on FormatException {
        throw const BackupCodecException(
            type: BackupCodecErrorType.invalidFormat,
            message: 'The backup contents are invalid.',
        );
        } finally {
            secretKey.destroy();
        }
    }

    void _validateNewPassword(String password) {
        if (password.length < minimumPasswordLength) {
        throw const BackupCodecException(
            type: BackupCodecErrorType.weakPassword,
            message:'Use a backup password with at least 12 characters.',
        );
        }

        if (password.length > 256) {
        throw const BackupCodecException(
            type: BackupCodecErrorType.weakPassword,
            message: 'The backup password is too long.',
            );
        }
    }

    Map<String, dynamic> _decodeEnvelope(List<int> backupBytes,) {
        try {
        final decoded = jsonDecode(utf8.decode(backupBytes),);

        if (decoded is! Map<String, dynamic>) {
            throw const FormatException();
        }

        if (_requiredString(decoded, 'format') != formatName) {
            throw const BackupCodecException(
                type: BackupCodecErrorType.invalidFormat,
                message: 'This is not a LucentVisit backup.',
            );
        }

        if (_requiredInt(decoded, 'version') != formatVersion) {
            throw const BackupCodecException(
            type: BackupCodecErrorType.unsupportedVersion,
            message: 'This backup was created by an unsupported version.',
            );
        }

        return decoded;
        } on BackupCodecException {
            rethrow;
        } on FormatException {
        throw const BackupCodecException(
            type: BackupCodecErrorType.invalidFormat,
            message: 'The backup file is damaged or invalid.',
            );
        }
    }

    Map<String, dynamic> _requiredMap(Map<String, dynamic> source, String key,) {
    final value = source[key];

    if (value is! Map<String, dynamic>) {
        throw const BackupCodecException(
            type: BackupCodecErrorType.invalidFormat,
            message: 'The backup file is damaged or invalid.',
        );
    }

        return value;
    }

    String _requiredString(Map<String, dynamic> source, String key,) {
    final value = source[key];

    if (value is! String) {
        throw const BackupCodecException(
            type: BackupCodecErrorType.invalidFormat,
            message: 'The backup file is damaged or invalid.',
            );
        }

        return value;
    }

    int _requiredInt(Map<String, dynamic> source, String key,) {
        final value = source[key];

        if (value is! int) {
        throw const BackupCodecException(
            type: BackupCodecErrorType.invalidFormat,
            message: 'The backup file is damaged or invalid.',
        );
        }

        return value;
    }

    List<int> _decodeBase64(Map<String, dynamic> source, String key,) {
        try {
        return base64Decode(_requiredString(source, key));
        } on FormatException {
        throw const BackupCodecException(
            type: BackupCodecErrorType.invalidFormat,
            message: 'The backup file is damaged or invalid.',
            );
        }
    }
}
