import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucentvisit/src/data/backup/backup_codec.dart';
import 'package:lucentvisit/src/data/backup/backup_models.dart';
import 'package:lucentvisit/src/data/lucentvisit_database.dart';
import 'package:lucentvisit/src/data/sql_lucentvisit_repository.dart';
import 'package:lucentvisit/src/models/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lucentvisit/src/data/backup/backup_service.dart';

void main() {
  late BackupCodec codec;
  late Uint8List encryptedBackup;

  const password = 'a-long-test-password';

  final payload = <String, dynamic>{
    'payload_version': 1,
    'created_at': '2026-10-04T12:00:00.000Z',
    'data': {
      'appointments': <dynamic>[],
      'medications': <dynamic>[],
      'health_log': <dynamic>[],
      'measurements': <dynamic>[],
    },
  };

  setUpAll(() async {
    sqfliteFfiInit();

    codec = BackupCodec();

    encryptedBackup = await codec.encrypt(
      payload: payload,
      password: password,
    );
  });

  test(
    'encrypts and decrypts a backup round trip',
    () async {
      final encryptedText = utf8.decode(encryptedBackup);

      // Record names belong inside the encrypted payload and
      // should not be visible in the saved backup file.
      expect(
        encryptedText,
        isNot(contains('"appointments"')),
      );

      final decrypted = await codec.decrypt(
        backupBytes: encryptedBackup,
        password: password,
      );

      expect(decrypted, payload);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'rejects an incorrect password',
    () async {
      await expectLater(
        codec.decrypt(
          backupBytes: encryptedBackup,
          password: 'a-different-password',
        ),
        throwsA(
          isA<BackupCodecException>()
              .having(
                (error) => error.type,
                'type',
                BackupCodecErrorType.authenticationFailed,
              )
              .having(
                (error) => error.message,
                'message',
                contains('incorrect or'),
              ),
        ),
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'rejects modified encrypted data',
    () async {
      final envelope =
          jsonDecode(
                utf8.decode(encryptedBackup),
              )
              as Map<String, dynamic>;

      final cipher =
          envelope['cipher'] as Map<String, dynamic>;

      final ciphertext = base64Decode(
        cipher['ciphertext'] as String,
      );

      expect(ciphertext, isNotEmpty);

      // Modifying one encrypted byte must cause AES-GCM
      // authentication to reject the entire file.
      ciphertext[0] ^= 1;

      cipher['ciphertext'] = base64Encode(ciphertext);

      final corruptedBackup = Uint8List.fromList(
        utf8.encode(jsonEncode(envelope)),
      );

      await expectLater(
        codec.decrypt(
          backupBytes: corruptedBackup,
          password: password,
        ),
        throwsA(
          isA<BackupCodecException>().having(
            (error) => error.type,
            'type',
            BackupCodecErrorType.authenticationFailed,
          ),
        ),
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'rejects a malformed backup envelope',
    () async {
      final malformedBackup = Uint8List.fromList(
        utf8.encode('{"not":"a backup"}'),
      );

      await expectLater(
        codec.decrypt(
          backupBytes: malformedBackup,
          password: password,
        ),
        throwsA(
          isA<BackupCodecException>().having(
            (error) => error.type,
            'type',
            BackupCodecErrorType.invalidFormat,
          ),
        ),
      );
    },
  );

  test(
    'rejects an unsupported backup format version',
    () async {
      final unsupportedBackup = Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'format': BackupCodec.formatName,
            'version': 999,
          }),
        ),
      );

      await expectLater(
        codec.decrypt(
          backupBytes: unsupportedBackup,
          password: password,
        ),
        throwsA(
          isA<BackupCodecException>().having(
            (error) => error.type,
            'type',
            BackupCodecErrorType.unsupportedVersion,
          ),
        ),
      );
    },
  );

  test(
    'rejects an empty backup file',
    () async {
      await expectLater(
        codec.decrypt(
          backupBytes: const <int>[],
          password: password,
        ),
        throwsA(
          isA<BackupCodecException>().having(
            (error) => error.type,
            'type',
            BackupCodecErrorType.tooLarge,
          ),
        ),
      );
    },
  );

  test(
    'rejects a short export password',
    () async {
      await expectLater(
        codec.encrypt(
          payload: payload,
          password: 'short',
        ),
        throwsA(
          isA<BackupCodecException>().having(
            (error) => error.type,
            'type',
            BackupCodecErrorType.weakPassword,
          ),
        ),
      );
    },
  );

  test(
    'uses fresh random values for every export',
    () async {
      final first = await codec.encrypt(
        payload: payload,
        password: password,
      );

      final second = await codec.encrypt(
        payload: payload,
        password: password,
      );

      expect(first, isNot(equals(second)));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'rolls back every insertion when one record fails',
    () async {
      final rawDatabase =
          await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
      );

      try {
        await _createTestSchema(rawDatabase);

        final database = LucentVisitDatabase.forTesting(
          rawDatabase,
        );

        final repository = SqlLucentVisitRepository(
          database,
        );

        // The repository inserts appointments before
        // measurements. This trigger forces the later
        // measurement insert to fail.
        await rawDatabase.execute('''
          CREATE TRIGGER reject_test_measurement
          BEFORE INSERT ON measurements
          BEGIN
            SELECT RAISE(ABORT, 'forced test failure');
          END
        ''');

        final snapshot = BackupSnapshot(
          appointments: [
            Appointment(
              id: 'appointment-from-backup',
              date: DateTime.utc(
                2026,
                10,
                20,
                14,
                30,
              ),
              reason: 'Follow-up',
            ),
          ],
          medications: const [],
          healthLog: const [],
          measurements: [
            Measurement(
              id: 'measurement-from-backup',
              measuredAt: DateTime.utc(
                2026,
                10,
                19,
              ),
              type: 'Blood pressure',
              value: '120/80',
              unit: 'mmHg',
            ),
          ],
        );

        await expectLater(
          repository.restoreMissingAtomically(
            snapshot,
          ),
          throwsA(anything),
        );

        final appointments = await rawDatabase.query(
          'appointments',
        );

        final measurements = await rawDatabase.query(
          'measurements',
        );

        // The appointment was inserted before the forced
        // measurement failure. It must still be absent because
        // the transaction rolled back.
        expect(appointments, isEmpty);
        expect(measurements, isEmpty);
      } finally {
        await rawDatabase.close();
      }
    },
  );
}

Future<void> _createTestSchema(
  Database database,
) async {
  await database.execute('''
    CREATE TABLE appointments (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL,
      reason TEXT NOT NULL,
      provider TEXT NOT NULL,
      documents TEXT NOT NULL,
      symptoms TEXT NOT NULL,
      questions TEXT NOT NULL,
      reminder_minutes INTEGER NOT NULL DEFAULT -1
    )
  ''');

  await database.execute('''
    CREATE TABLE medications (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      strength TEXT NOT NULL,
      dose TEXT NOT NULL,
      schedule TEXT NOT NULL,
      notes TEXT NOT NULL,
      active INTEGER NOT NULL CHECK(active IN (0, 1)),
      times TEXT NOT NULL DEFAULT '',
      reminder_minutes INTEGER NOT NULL DEFAULT -1
    )
  ''');

  await database.execute('''
    CREATE TABLE health_log_entries (
      id TEXT PRIMARY KEY,
      occurred_at TEXT NOT NULL,
      text TEXT NOT NULL,
      flagged INTEGER NOT NULL CHECK(flagged IN (0, 1))
    )
  ''');

  await database.execute('''
    CREATE TABLE measurements (
      id TEXT PRIMARY KEY,
      measured_at TEXT NOT NULL,
      type TEXT NOT NULL,
      value TEXT NOT NULL,
      unit TEXT NOT NULL,
      context TEXT NOT NULL
    )
  ''');

    test(
    'exports, previews, and restores only missing entries',
    () async {
      final service = BackupService();

      late Uint8List backupBytes;

      // Build the encrypted backup from a source database.
      final sourceDatabase =
          await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
      );

      try {
        await _createTestSchema(sourceDatabase);

        final sourceRepository =
          SqlLucentVisitRepository(
          LucentVisitDatabase.forTesting(
            sourceDatabase,
          ),
        );

        await sourceRepository.saveAppointment(
          Appointment(
            id: 'shared-appointment',
            date: DateTime.utc(2026, 10, 20, 14, 30),
            reason: 'Appointment from backup',
          ),
        );

        await sourceRepository.saveMedication(
          const Medication(
            id: 'new-medication',
            name: 'Example medication',
            strength: '10 mg',
          ),
        );

        await sourceRepository.saveHealthLogEntry(
          HealthLogEntry(
            id: 'new-health-note',
            occurredAt: DateTime.utc(2026, 10, 18),
            text: 'Example health note',
          ),
        );

        await sourceRepository.saveMeasurement(
          Measurement(
            id: 'new-measurement',
            measuredAt: DateTime.utc(2026, 10, 19),
            type: 'Blood pressure',
            value: '120/80',
            unit: 'mmHg',
          ),
        );

      backupBytes = await service.createBackup(
        repository: sourceRepository,
        password: password,
        );
      } finally {
        await sourceDatabase.close();
      }

      // Restore into a different database that already contains
      // one record with the same stable ID.
      final targetDatabase =
          await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
      );

      try {
        await _createTestSchema(targetDatabase);

        final targetRepository =
          SqlLucentVisitRepository(
          LucentVisitDatabase.forTesting(
          targetDatabase,
          ),
        );

        await targetRepository.saveAppointment(
          Appointment(
            id: 'shared-appointment',
            date: DateTime.utc(2026, 11, 1, 9),
            reason: 'Keep this local appointment',
          ),
        );

        final prepared = await service.prepareRestore(
          backupBytes: backupBytes,
          password: password,
          repository: targetRepository,
        );

        expect(
          prepared.preview.appointmentsInFile,
          1,
        );
        expect(
          prepared.preview.medicationsInFile,
          1,
        );
        expect(
          prepared.preview.healthNotesInFile,
          1,
        );
        expect(
          prepared.preview.measurementsInFile,
          1,
        );

        expect(
          prepared.preview.appointmentsToAdd,
          0,
        );
        expect(
          prepared.preview.medicationsToAdd,
          1,
        );
        expect(
          prepared.preview.healthNotesToAdd,
          1,
        );
        expect(
          prepared.preview.measurementsToAdd,
          1,
        );

        expect(prepared.preview.totalInFile, 4);
        expect(prepared.preview.totalToAdd, 3);
        expect(prepared.preview.totalSkipped, 1);

        final result = await service.restorePrepared(
          prepared: prepared,
          repository: targetRepository,
        );

        expect(result.added, 3);
        expect(result.skipped, 1);

        final appointments =
            await targetRepository.appointments();

        final medications =
            await targetRepository.medications();

        final healthLog =
            await targetRepository.healthLog();

        final measurements =
            await targetRepository.measurements();

        // The existing appointment must not be overwritten.
        expect(appointments, hasLength(1));
        expect(
          appointments.single.reason,
          'Keep this local appointment',
        );

        expect(medications, hasLength(1));
        expect(
          medications.single.id,
          'new-medication',
        );

        expect(healthLog, hasLength(1));
        expect(
          healthLog.single.id,
          'new-health-note',
        );

        expect(measurements, hasLength(1));
        expect(
          measurements.single.id,
          'new-measurement',
        );
      } finally {
        await targetDatabase.close();
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}