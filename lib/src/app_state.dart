import 'package:flutter/material.dart';

import 'data/lucentvisit_repository.dart';
import 'models/models.dart';
import 'notifications/reminder_service.dart';

/// Coordinates screen state, persistence, and reminder synchronization.
///
/// Screens send user actions here rather than writing directly to storage.
/// After each mutation, [load] refreshes the in-memory source of truth and then
/// rebuilds reminders from the newly persisted records.
class AppState extends ChangeNotifier {
  AppState(this.repository, {this.reminders});

  final LucentVisitRepository repository;
  final ReminderService? reminders;
  bool loading = true;
  ThemeMode themeMode = ThemeMode.system;
  List<Appointment> appointments = [];
  List<Medication> medications = [];
  List<HealthLogEntry> healthLog = [];
  List<Measurement> measurements = [];

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final values = await Future.wait([
      repository.appointments(),
      repository.medications(),
      repository.healthLog(),
      repository.measurements(),
      repository.setting('theme_mode'),
    ]);
    appointments = values[0] as List<Appointment>;
    medications = values[1] as List<Medication>;
    healthLog = values[2] as List<HealthLogEntry>;
    measurements = values[3] as List<Measurement>;
    themeMode = _themeModeFromName(values[4] as String?);
    loading = false;
    notifyListeners();
    await reminders?.sync(appointments, medications);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    notifyListeners();
    await repository.saveSetting('theme_mode', value.name);
  }

  Future<void> addAppointment(Appointment value) async {
    await repository.saveAppointment(value);
    await load();
  }

  Future<void> addMedication(Medication value) async {
    await repository.saveMedication(value);
    await load();
  }

  Future<void> addLog(HealthLogEntry value) async {
    await repository.saveHealthLogEntry(value);
    await load();
  }

  Future<void> addMeasurement(Measurement value) async {
    await repository.saveMeasurement(value);
    await load();
  }

  Future<void> deleteAppointment(String id) async {
    await repository.deleteAppointment(id);
    await load();
  }

  Future<void> deleteMedication(String id) async {
    await repository.deleteMedication(id);
    await load();
  }

  Future<void> deleteLog(String id) async {
    await repository.deleteHealthLogEntry(id);
    await load();
  }

  Future<void> deleteMeasurement(String id) async {
    await repository.deleteMeasurement(id);
    await load();
  }

  Future<void> deleteEverything() async {
    await repository.deleteEverything();
    await load();
  }

  ThemeMode _themeModeFromName(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
