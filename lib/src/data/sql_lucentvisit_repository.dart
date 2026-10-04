import 'package:sqflite_sqlcipher/sqflite.dart';

import '../models/models.dart';
import 'backup/backup_models.dart';
import 'backup/backup_repository.dart';
import 'lucentvisit_database.dart';
import 'lucentvisit_repository.dart';

/// Maps the repository contract to the encrypted mobile SQL database.
///
/// The ordering guarantees are part of the screen behavior, and stable-ID
/// upserts ensure that editing an entry does not create a duplicate.
class SqlLucentVisitRepository
    implements LucentVisitRepository, AtomicBackupRepository {
  SqlLucentVisitRepository(this.database);

  final LucentVisitDatabase database;

  @override
  Future<List<Appointment>> appointments() async {
    final rows = await database.db.query('appointments', orderBy: 'date ASC');
    return rows.map(Appointment.fromMap).toList();
  }

  @override
  Future<List<Medication>> medications() async {
    final rows = await database.db.query(
      'medications',
      orderBy: 'active DESC, name COLLATE NOCASE ASC',
    );
    return rows.map(Medication.fromMap).toList();
  }

  @override
  Future<List<HealthLogEntry>> healthLog() async {
    final rows = await database.db.query(
      'health_log_entries',
      orderBy: 'occurred_at DESC',
    );
    return rows.map(HealthLogEntry.fromMap).toList();
  }

  @override
  Future<List<Measurement>> measurements() async {
    final rows = await database.db.query(
      'measurements',
      orderBy: 'measured_at DESC',
    );
    return rows.map(Measurement.fromMap).toList();
  }

  @override
  Future<void> saveAppointment(Appointment value) => database.db.insert(
    'appointments',
    value.toMap(),
    // `replace` implements the repository's stable-ID upsert contract.
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  @override
  Future<void> saveMedication(Medication value) => database.db.insert(
    'medications',
    value.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  @override
  Future<void> saveHealthLogEntry(HealthLogEntry value) => database.db.insert(
    'health_log_entries',
    value.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  @override
  Future<void> saveMeasurement(Measurement value) => database.db.insert(
    'measurements',
    value.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  @override
  Future<void> deleteAppointment(String id) =>
      // Values stay in whereArgs instead of being interpolated into SQL.
      database.db.delete('appointments', where: 'id = ?', whereArgs: [id]);

  @override
  Future<void> deleteMedication(String id) =>
      database.db.delete('medications', where: 'id = ?', whereArgs: [id]);

  @override
  Future<void> deleteHealthLogEntry(String id) => database.db.delete(
    'health_log_entries',
    where: 'id = ?',
    whereArgs: [id],
  );

  @override
  Future<void> deleteMeasurement(String id) =>
      database.db.delete('measurements', where: 'id = ?', whereArgs: [id]);

  @override
  Future<String?> setting(String key) async {
    final rows = await database.db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  @override
  Future<void> saveSetting(String key, String value) => database.db.insert(
    'settings',
    {'key': key, 'value': value},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  @override
  Future<void> deleteEverything() => database.db.transaction((txn) async {
    // A transaction prevents a partial erase if one table operation fails.
    // Settings intentionally remain so display preferences are preserved.
    for (final table in [
      'appointments',
      'medications',
      'health_log_entries',
      'measurements',
    ]) {
      await txn.delete(table);
    }
  });

  @override
  Future<BackupRestoreResult> restoreMissingAtomically(
    BackupSnapshot snapshot,
  ) => database.db.transaction((txn) async {
    Future<Set<String>> ids(String table) async => (await txn.query(
      table,
      columns: ['id'],
    )).map((row) => row['id']! as String).toSet();

    final appointmentIds = await ids('appointments');
    final medicationIds = await ids('medications');
    final healthLogIds = await ids('health_log_entries');
    final measurementIds = await ids('measurements');

    var appointments = 0;
    var medications = 0;
    var healthLogEntries = 0;
    var measurements = 0;

    for (final value in snapshot.appointments) {
      if (appointmentIds.add(value.id)) {
        await txn.insert(
          'appointments',
          value.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        appointments++;
      }
    }
    for (final value in snapshot.medications) {
      if (medicationIds.add(value.id)) {
        await txn.insert(
          'medications',
          value.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        medications++;
      }
    }
    for (final value in snapshot.healthLog) {
      if (healthLogIds.add(value.id)) {
        await txn.insert(
          'health_log_entries',
          value.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        healthLogEntries++;
      }
    }
    for (final value in snapshot.measurements) {
      if (measurementIds.add(value.id)) {
        await txn.insert(
          'measurements',
          value.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        measurements++;
      }
    }

    return BackupRestoreResult(
      appointments: appointments,
      medications: medications,
      healthLogEntries: healthLogEntries,
      measurements: measurements,
    );
  });
}
