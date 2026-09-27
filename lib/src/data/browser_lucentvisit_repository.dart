// This file is only imported by the web entry point. It intentionally uses
// browser localStorage so the GitHub Pages build stays local-first without a
// server or cloud database.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import '../models/models.dart';
import 'lucentvisit_repository.dart';

/// Web-only storage adapter used by the GitHub Pages demonstration.
///
/// Browser localStorage is on-device but is not encrypted like the SQLCipher
/// database, so the hosted demo must not imply equivalent protection.
class BrowserLucentVisitRepository implements LucentVisitRepository {
  static const _prefix = 'clearvisit.web.v1';

  @override
  Future<List<Appointment>> appointments() async {
    final values = _readList('appointments', (map) => Appointment.fromMap(map))
      ..sort((a, b) => a.date.compareTo(b.date));
    return values;
  }

  @override
  Future<List<Medication>> medications() async {
    final values = _readList('medications', (map) => Medication.fromMap(map))
      ..sort((a, b) {
        if (a.active != b.active) return a.active ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return values;
  }

  @override
  Future<List<HealthLogEntry>> healthLog() async {
    final values = _readList(
      'health_log_entries',
      (map) => HealthLogEntry.fromMap(map),
    )..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return values;
  }

  @override
  Future<List<Measurement>> measurements() async {
    final values = _readList('measurements', (map) => Measurement.fromMap(map))
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    return values;
  }

  @override
  Future<void> saveAppointment(Appointment value) =>
      _upsert('appointments', value.toMap());

  @override
  Future<void> saveMedication(Medication value) =>
      _upsert('medications', value.toMap());

  @override
  Future<void> saveHealthLogEntry(HealthLogEntry value) =>
      _upsert('health_log_entries', value.toMap());

  @override
  Future<void> saveMeasurement(Measurement value) =>
      _upsert('measurements', value.toMap());

  @override
  Future<void> deleteAppointment(String id) => _deleteById('appointments', id);

  @override
  Future<void> deleteMedication(String id) => _deleteById('medications', id);

  @override
  Future<void> deleteHealthLogEntry(String id) =>
      _deleteById('health_log_entries', id);

  @override
  Future<void> deleteMeasurement(String id) => _deleteById('measurements', id);

  @override
  Future<String?> setting(String key) async =>
      html.window.localStorage[_storageKey('settings.$key')];

  @override
  Future<void> saveSetting(String key, String value) async {
    html.window.localStorage[_storageKey('settings.$key')] = value;
  }

  @override
  Future<void> deleteEverything() async {
    for (final key in [
      'appointments',
      'medications',
      'health_log_entries',
      'measurements',
    ]) {
      html.window.localStorage.remove(_storageKey(key));
    }
  }

  List<T> _readList<T>(
    String key,
    T Function(Map<String, Object?> map) fromMap,
  ) {
    final raw = html.window.localStorage[_storageKey(key)];
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((map) => fromMap(Map<String, Object?>.from(map)))
        .toList();
  }

  Future<void> _upsert(String key, Map<String, Object?> value) async {
    // Match the mobile repository: replace a record with the same stable ID or
    // append it when the ID has not been seen before.
    final rows = _readRawList(key);
    final id = value['id'];
    final existingIndex = rows.indexWhere((row) => row['id'] == id);
    if (existingIndex >= 0) {
      rows[existingIndex] = value;
    } else {
      rows.add(value);
    }
    html.window.localStorage[_storageKey(key)] = jsonEncode(rows);
  }

  Future<void> _deleteById(String key, String id) async {
    final rows = _readRawList(key)..removeWhere((row) => row['id'] == id);
    html.window.localStorage[_storageKey(key)] = jsonEncode(rows);
  }

  List<Map<String, Object?>> _readRawList(String key) {
    final raw = html.window.localStorage[_storageKey(key)];
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((map) => Map<String, Object?>.from(map))
        .toList();
  }

  String _storageKey(String key) => '$_prefix.$key';
}
