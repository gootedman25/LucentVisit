import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../models/models.dart';
import 'lucentvisit_repository.dart';

class BackupData {
  const BackupData({
    required this.appointments,
    required this.medications,
    required this.healthLog,
    required this.measurements,
  });

  final List<Appointment> appointments;
  final List<Medication> medications;
  final List<HealthLogEntry> healthLog;
  final List<Measurement> measurements;

  String get summary =>
      '${appointments.length} appointments, '
      '${medications.length} medications, ${healthLog.length} health notes, '
      '${measurements.length} measurements';

  Map<String, Object?> toMap() => {
    'appointments': appointments.map((entry) => entry.toMap()).toList(),
    'medications': medications.map((entry) => entry.toMap()).toList(),
    'health_log': healthLog.map((entry) => entry.toMap()).toList(),
    'measurements': measurements.map((entry) => entry.toMap()).toList(),
  };

  factory BackupData.fromMap(Map<String, dynamic> map) {
    // Treat imported backups as untrusted input. Limits and unique, non-empty
    // IDs prevent unreasonable allocations and ambiguous restore behavior.
    List<T> read<T>(String name, T Function(Map<String, Object?>) parse) {
      final rows = map[name];
      if (rows is! List || rows.length > 10000) {
        throw const FormatException('Invalid backup records.');
      }
      final ids = <String>{};
      return rows.map((row) {
        if (row is! Map<String, dynamic> ||
            row['id'] is! String ||
            (row['id'] as String).isEmpty ||
            !ids.add(row['id'] as String)) {
          throw const FormatException('Invalid or duplicate backup record.');
        }
        return parse(Map<String, Object?>.from(row));
      }).toList();
    }

    return BackupData(
      appointments: read('appointments', Appointment.fromMap),
      medications: read('medications', Medication.fromMap),
      healthLog: read('health_log', HealthLogEntry.fromMap),
      measurements: read('measurements', Measurement.fromMap),
    );
  }
}

/// Creates and restores passphrase-protected, on-device backup files.
///
/// No network calls or plaintext files are used, and the passphrase is never
/// persisted. AES-GCM supplies encryption plus tamper detection, while PBKDF2
/// turns the user's passphrase into a fixed-size encryption key.
class BackupService {
  static const maxFileBytes = 20 * 1024 * 1024;
  static final _cipher = AesGcm.with256bits();
  static final _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 210000,
    bits: 256,
  );

  Future<Uint8List> encrypt(BackupData data, String password) async {
    // Never produce a file that our own restore limits cannot accept.
    BackupData.fromMap(data.toMap());
    if (password.length < 12) {
      throw const FormatException(
        'Use a passphrase with at least 12 characters.',
      );
    }
    final random = Random.secure();
    final salt = List.generate(16, (_) => random.nextInt(256));
    final key = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(data.toMap())),
      secretKey: key,
    );
    final bytes = Uint8List.fromList(
      utf8.encode(
        // `format` and `version` form a file-format contract. Changes require a
        // migration path so previously exported backups remain restorable.
        jsonEncode({
          'format': 'lucentvisit-backup',
          'version': 1,
          'salt': base64Encode(salt),
          'nonce': base64Encode(box.nonce),
          'mac': base64Encode(box.mac.bytes),
          'ciphertext': base64Encode(box.cipherText),
        }),
      ),
    );
    if (bytes.length > maxFileBytes) {
      throw const FormatException('Backup exceeds the 20 MB file limit.');
    }
    return bytes;
  }

  Future<BackupData> decrypt(Uint8List bytes, String password) async {
    if (bytes.length > maxFileBytes) {
      throw const FormatException('Backup exceeds the 20 MB file limit.');
    }
    try {
      final envelope = jsonDecode(utf8.decode(bytes));
      if (envelope is! Map<String, dynamic> ||
          (envelope['format'] != 'lucentvisit-backup' &&
              envelope['format'] != 'carecue-backup' &&
              envelope['format'] != 'clearcue-backup') ||
          envelope['version'] != 1) {
        throw const FormatException();
      }
      final salt = base64Decode(envelope['salt'] as String);
      final nonce = base64Decode(envelope['nonce'] as String);
      final mac = base64Decode(envelope['mac'] as String);
      if (salt.length != 16 || nonce.length != 12 || mac.length != 16) {
        throw const FormatException();
      }
      final key = await _kdf.deriveKey(
        secretKey: SecretKey(utf8.encode(password)),
        nonce: salt,
      );
      final plaintext = await _cipher.decrypt(
        SecretBox(
          base64Decode(envelope['ciphertext'] as String),
          nonce: nonce,
          mac: Mac(mac),
        ),
        secretKey: key,
      );
      return BackupData.fromMap(
        jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>,
      );
    } catch (_) {
      // Use one message for a wrong passphrase, corruption, or malformed input;
      // callers do not need cryptographic failure details.
      throw const FormatException(
        'Cannot open backup. Check the passphrase and file.',
      );
    }
  }

  /// Add missing IDs only: never erase or overwrite newer on-device entries.
  /// Fully decrypted and validated before this method is called. If a save
  /// fails, retrying safely resumes without duplicating successful records.
  Future<int> restoreMissing(
    BackupData data,
    LucentVisitRepository repository,
  ) async {
    var added = 0;
    Future<void> merge<T>(
      List<T> incoming,
      List<T> current,
      String Function(T) idOf,
      Future<void> Function(T) save,
    ) async {
      final ids = current.map(idOf).toSet();
      for (final entry in incoming) {
        if (ids.add(idOf(entry))) {
          await save(entry);
          added++;
        }
      }
    }

    await merge(
      data.appointments,
      await repository.appointments(),
      (e) => e.id,
      repository.saveAppointment,
    );
    await merge(
      data.medications,
      await repository.medications(),
      (e) => e.id,
      repository.saveMedication,
    );
    await merge(
      data.healthLog,
      await repository.healthLog(),
      (e) => e.id,
      repository.saveHealthLogEntry,
    );
    await merge(
      data.measurements,
      await repository.measurements(),
      (e) => e.id,
      repository.saveMeasurement,
    );
    return added;
  }
}
