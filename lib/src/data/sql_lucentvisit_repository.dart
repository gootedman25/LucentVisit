import 'package:sqflite_sqlcipher/sqflite.dart';

import '../models/models.dart';
import 'lucentvisit_database.dart';
import 'lucentvisit_repository.dart';

/// Maps the repository contract to the encrypted mobile SQL database.
///
/// The ordering guarantees are part of the screen behavior, and stable-ID
/// upserts ensure that editing an entry does not create a duplicate.
class SqlLucentVisitRepository implements LucentVisitRepository {
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
}
