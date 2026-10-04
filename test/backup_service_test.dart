import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucentvisit/src/data/backup/backup_codec.dart';
import 'package:lucentvisit/src/data/backup/backup_models.dart';
import 'package:lucentvisit/src/data/backup/backup_service.dart';
import 'package:lucentvisit/src/data/lucentvisit_database.dart';
import 'package:lucentvisit/src/data/sql_lucentvisit_repository.dart';
import 'package:lucentvisit/src/models/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  const password = 'a unique backup password';
  final snapshot = BackupSnapshot(
    appointments: [
      Appointment(id: 'a', date: DateTime(2026, 9, 1), reason: 'Checkup'),
    ],
    medications: const [Medication(id: 'm', name: 'Private medicine')],
    healthLog: [
      HealthLogEntry(
        id: 'h',
        occurredAt: DateTime(2026, 9, 1),
        text: 'Private note',
      ),
    ],
    measurements: [
      Measurement(
        id: 'v',
        measuredAt: DateTime(2026, 9, 1),
        type: 'Blood pressure',
        value: '120/80',
        unit: 'mmHg',
      ),
    ],
  );

  test('codec encrypts and round trips a snapshot', () async {
    final codec = BackupCodec();
    final bytes = await codec.encode(
      payload: snapshot.toJson(),
      password: password,
    );
    expect(utf8.decode(bytes), isNot(contains('Private note')));
    final decoded = await codec.decode(bytes: bytes, password: password);
    final restored = BackupSnapshot.fromJson(decoded.payload);
    expect(restored.medications.single.name, 'Private medicine');
    expect(restored.measurements.single.systolic, 120);
  });

  test('wrong password and corrupted files are rejected', () async {
    final codec = BackupCodec();
    final bytes = await codec.encode(
      payload: snapshot.toJson(),
      password: password,
    );
    await expectLater(
      codec.decode(bytes: bytes, password: 'another long password'),
      throwsA(isA<BackupCodecException>()),
    );
    final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final cipherText = base64Decode(envelope['ciphertext'] as String);
    cipherText[0] ^= 1;
    envelope['ciphertext'] = base64Encode(cipherText);
    await expectLater(
      codec.decode(
        bytes: Uint8List.fromList(utf8.encode(jsonEncode(envelope))),
        password: password,
      ),
      throwsA(isA<BackupCodecException>()),
    );
  });

  test('restore is atomic and rolls back every insert on failure', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    addTearDown(db.close);
    await _createSchema(db);
    await db.execute('''
      CREATE TRIGGER fail_measurement BEFORE INSERT ON measurements
      BEGIN SELECT RAISE(ABORT, 'test failure'); END
    ''');
    final repository = SqlLucentVisitRepository(
      LucentVisitDatabase.forTesting(db),
    );
    await expectLater(
      repository.restoreMissingAtomically(snapshot),
      throwsA(anything),
    );
    expect((await db.query('appointments')), isEmpty);
    expect((await db.query('medications')), isEmpty);
    expect((await db.query('health_log_entries')), isEmpty);
    expect((await db.query('measurements')), isEmpty);
  });

  test('service previews before restoring and skips existing IDs', () async {
    sqfliteFfiInit();
    final sourceDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    final targetDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    addTearDown(sourceDb.close);
    addTearDown(targetDb.close);
    await _createSchema(sourceDb);
    await _createSchema(targetDb);
    final source = SqlLucentVisitRepository(
      LucentVisitDatabase.forTesting(sourceDb),
    );
    final target = SqlLucentVisitRepository(
      LucentVisitDatabase.forTesting(targetDb),
    );
    for (final value in snapshot.appointments) {
      await source.saveAppointment(value);
    }
    for (final value in snapshot.medications) {
      await source.saveMedication(value);
    }
    for (final value in snapshot.healthLog) {
      await source.saveHealthLogEntry(value);
    }
    for (final value in snapshot.measurements) {
      await source.saveMeasurement(value);
    }
    await target.saveMedication(const Medication(id: 'm', name: 'Newer label'));

    final bytes = await BackupService(source).createBackup(password);
    final prepared = await BackupService(
      target,
    ).prepareRestore(bytes, password);
    expect(prepared.preview.total, 4);
    final result = await BackupService(target).restorePrepared(prepared);
    expect(result.total, 3);
    expect((await target.medications()).single.name, 'Newer label');
    expect((await BackupService(target).restorePrepared(prepared)).total, 0);
  });
}

Future<void> _createSchema(Database db) async {
  await db.execute('''CREATE TABLE appointments (
    id TEXT PRIMARY KEY, date TEXT NOT NULL, reason TEXT NOT NULL,
    provider TEXT NOT NULL, documents TEXT NOT NULL, symptoms TEXT NOT NULL,
    questions TEXT NOT NULL, reminder_minutes INTEGER NOT NULL DEFAULT -1)''');
  await db.execute('''CREATE TABLE medications (
    id TEXT PRIMARY KEY, name TEXT NOT NULL, strength TEXT NOT NULL,
    dose TEXT NOT NULL, schedule TEXT NOT NULL, notes TEXT NOT NULL,
    active INTEGER NOT NULL, times TEXT NOT NULL DEFAULT '',
    reminder_minutes INTEGER NOT NULL DEFAULT -1)''');
  await db.execute('''CREATE TABLE health_log_entries (
    id TEXT PRIMARY KEY, occurred_at TEXT NOT NULL, text TEXT NOT NULL,
    flagged INTEGER NOT NULL)''');
  await db.execute('''CREATE TABLE measurements (
    id TEXT PRIMARY KEY, measured_at TEXT NOT NULL, type TEXT NOT NULL,
    value TEXT NOT NULL, unit TEXT NOT NULL, context TEXT NOT NULL)''');
  await db.execute(
    'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
  );
}
