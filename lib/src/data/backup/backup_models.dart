import '../../models/models.dart';

const backupSchemaVersion = 1;

class BackupSnapshot {
  const BackupSnapshot({
    required this.appointments,
    required this.medications,
    required this.healthLog,
    required this.measurements,
  });

  final List<Appointment> appointments;
  final List<Medication> medications;
  final List<HealthLogEntry> healthLog;
  final List<Measurement> measurements;

  Map<String, Object?> toJson() => {
    'schema_version': backupSchemaVersion,
    'appointments': appointments.map((value) => value.toMap()).toList(),
    'medications': medications.map((value) => value.toMap()).toList(),
    'health_log': healthLog.map((value) => value.toMap()).toList(),
    'measurements': measurements.map((value) => value.toMap()).toList(),
  };

  factory BackupSnapshot.fromJson(Map<String, Object?> json) {
    if (json['schema_version'] != backupSchemaVersion) {
      throw const FormatException('Unsupported backup schema.');
    }
    return BackupSnapshot(
      appointments: _maps(
        json,
        'appointments',
      ).map(Appointment.fromMap).toList(),
      medications: _maps(json, 'medications').map(Medication.fromMap).toList(),
      healthLog: _maps(json, 'health_log').map(HealthLogEntry.fromMap).toList(),
      measurements: _maps(
        json,
        'measurements',
      ).map(Measurement.fromMap).toList(),
    );
  }

  static Iterable<Map<String, Object?>> _maps(
    Map<String, Object?> json,
    String key,
  ) {
    final values = json[key];
    if (values is! List) throw FormatException('Invalid $key list.');
    return values.map((value) {
      if (value is! Map) throw FormatException('Invalid $key entry.');
      return value.map((key, value) => MapEntry(key.toString(), value));
    });
  }
}

class BackupPreview {
  const BackupPreview({
    required this.createdAt,
    required this.appointments,
    required this.medications,
    required this.healthLogEntries,
    required this.measurements,
  });

  final DateTime createdAt;
  final int appointments;
  final int medications;
  final int healthLogEntries;
  final int measurements;

  int get total => appointments + medications + healthLogEntries + measurements;
}

class PreparedBackupRestore {
  const PreparedBackupRestore({required this.snapshot, required this.preview});

  final BackupSnapshot snapshot;
  final BackupPreview preview;
}

class BackupRestoreResult {
  const BackupRestoreResult({
    required this.appointments,
    required this.medications,
    required this.healthLogEntries,
    required this.measurements,
  });

  final int appointments;
  final int medications;
  final int healthLogEntries;
  final int measurements;

  int get total => appointments + medications + healthLogEntries + measurements;
}
