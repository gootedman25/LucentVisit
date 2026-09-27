import '../models/models.dart';

/// The storage contract used by the rest of the app.
///
/// Widgets and [AppState] depend on this interface instead of knowing whether
/// data is stored in SQLCipher or browser localStorage. Every `save` operation
/// is an upsert: an existing stable ID is updated and a new ID is inserted.
abstract interface class LucentVisitRepository {
  Future<List<Appointment>> appointments();

  Future<List<Medication>> medications();

  Future<List<HealthLogEntry>> healthLog();

  Future<List<Measurement>> measurements();

  Future<void> saveAppointment(Appointment value);

  Future<void> saveMedication(Medication value);

  Future<void> saveHealthLogEntry(HealthLogEntry value);

  Future<void> saveMeasurement(Measurement value);

  Future<void> deleteAppointment(String id);

  Future<void> deleteMedication(String id);

  Future<void> deleteHealthLogEntry(String id);

  Future<void> deleteMeasurement(String id);

  Future<String?> setting(String key);

  Future<void> saveSetting(String key, String value);

  Future<void> deleteEverything();
}
