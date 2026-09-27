import '../models/models.dart';

abstract interface class ReminderService {
  Future<void> sync(
    List<Appointment> appointments,
    List<Medication> medications,
  );
}
