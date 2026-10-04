import '../../models/models.dart';

class BackupSnapshot {
    const BackupSnapshot({
        required this.appointments,
        required this.medications,
        required this.healthLog,
        required this.measurments,
    });

    static const int MaximumRecordsPerType = 10000;
    static const int MaximumStringLength = 100000;

    final List<Appointment> appointments;
    final List<Medication> medications;
    final List<HealthLog> healthLog;
    final List<Measurement> measurements;

    int get totalRecords =>
        appointments.length +
        medications.length +
        healthLog.length +
        measurements.length;

    Map<String, dynamic> toJson() {
        return {
            'appointments': appointments.map((value) => value.toMap()).toList(growable: false),
            'medications': medications.map((value) => value.toJson())).toList(growable: false),
            'healthLog': healthLog.map((value) => value.toJson())).toList(growable: false),
            'measurements': measurements.map((value) => value.toJson()).toList(growable: false),
        };
    }

    factory BackupSnapshot.fromJson(Map<String, dynamic> json) {
        return BackupSnapshot(
            appointments: _readRecords(json: json, key: 'appointments', parser: Appointment.fromMap,),
            medications: _readRecords(json: json, key: 'medications', parser: Medication.fromJson),
            healthLog: _readRecords(json: json, key: 'healthLog', parser: HealthLog.fromJson),
            measurements: _readRecords(json: json, key: 'measurements', parser: Measurement.fromJson),
        );
    }
}

class BackupPayload {
    const BackupPayload({
        required this.snapshot,
        required this.createdAtUtc,
    });

    static const int payloadVersion = 1;

    final BackupSnapshot snapshot;
    final DateTime createdAtUtc;

    Map<String, dynamic> toJson() {
        return {
            'payload_version': payloadVersion,
            'data': snapshot.toJson(),
            'createdAtUtc': createdAtUtc.toIso8601String(),
        };
    }

    factory BackupPayload.fromJson(Map<String, dynamic> json) {
        if(json['payload_version'] != payloadVersion) {
            throw FormatException('Unsupported payload version');
    }

    final createdAtValue = json['createdAtUtc'];
    final dataValue = json['data'];

    if (createdAtValue is! String || dataValue is! Map<String, dynamic>) {
        throw FormatException('Invalid backup contents');
    }

    final DateTime createdAt;

        try{
        createdAt = DateTime.parse(createdAtValue).toUtc();
        } on FormatException  {
        throw const FormatException('Invalid backup creation date');
        }

        return BackupPayload(
        snapshot: BackupSnapshot.fromJson(dataValue),
        createdAtUtc: createdAt,
        );
    }
}

class BackupPreview {
    const BackupPreview({
        required this.createdAtUtc,
        required this.appointmentsInFile,
        required this.medicationsInFile,
        required this.healthLogInFile,
        required this.measurmentsInFile,
        required this.appointmentsToAdd,
        required this.medicationsTo medicationsToAdd,
        required this.healthLogToHealthLogToAdd,
        required this.measurmentsToMeasurmentsToAdd,
    });

    final DateTime createdAtUtc;
    final int appointmentsInFile;
    final int medicationsInFile;
    final int healthLogInFile;
    final int measurmentsInFile;
    final int appointmentsToAdd;
    final int medicationsToAdd;
    final int healthLogToAdd;
    final int measurmentsToAdd;

    int get totalInFile => appointmentsInFile + medicationsInFile + healthLogInFile + measurmentsInFile;
    int get totalToAdd => appointmentsToAdd + medicationsToAdd + healthLogToAdd + measurmentsToAdd;
    int get totalSkipped => totalInFile - totalToAdd;
}

class PreparedBackupRestore {
    const PreparedBackupRestore({
        required this.snapshot,
        required this.preview,
    });

    final BackupSnapshot snapshot;
    final BackupPreview preview;
}

class BackupRestoreResult {
    const BackupRestoreResult({
        required this.added,
        required this.skipped,
    });

    final int added;
    final int skipped;
}

List<T> _readRecords<T>({
    required Map<String, dynamic> json,
    required String key,
    required T Function(Map<String, Object?>) parser,
}) {
    final value = json[key];

    if (value is! List || value.length > BackupSnapshot.maxRecordsPerType) {
        throw FormatException('Invalid records for key: $key');
    }

    final ids = <String>[];
    final records = <T>[];

    for (final item in value) {
        if (item is! Map<String, Object?>) {
            throw FormatException('Invalid item in records for key: $key');
        }

        _validateRecordValue(item);
        
        if(id is! String || id.trim().isEmpty || !ids.add(id)) {
            throw FormatException('Invalid id in records for key: $key');
        }

        try {
            records.add(parser(Map<String, Object?>.from(item)));
        } on FormatException {
            throw FormatException('Failed to parse record for key: $key');
        } on TypeError {
            throw FormatException('Failed to parse record for key: $key');
        } on ArgumentError {
            throw FormatException('Failed to parse record for key: $key');
        }
    }

    return List<T>.unmodifiable(records);
}

void _validateRecordValue(Map<String, dynamic> record) {
    for (final entry in record.entries) {
        final value = entry.value;

        if (value is String && value.length > BackupSnapshot.maxStringLength) {
            throw FormatException('Value for key: ${entry.key} exceeds maximum string length');
        }
    }

    if (value != null && value is! String && value is! int && value is! bool) {
        throw FormatException('Value for key: ${entry.key} has unsupported type');
    }
}