import 'dart:math';

String newId() {
  final random = Random.secure();
  final suffix = List.generate(
    12,
    (_) => random.nextInt(16).toRadixString(16),
  ).join();
  return '${DateTime.now().microsecondsSinceEpoch}-$suffix';
}

class Appointment {
  const Appointment({
    required this.id,
    required this.date,
    required this.reason,
    this.provider = '',
    this.documents = '',
    this.symptoms = '',
    this.questions = '',
    this.reminderMinutes = -1,
  });

  final String id;
  final DateTime date;
  final String reason;
  final String provider;
  final String documents;
  final String symptoms;
  final String questions;

  /// Minutes before [date] to show a reminder. -1 means no reminder.
  final int reminderMinutes;

  Map<String, Object?> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'reason': reason,
    'provider': provider,
    'documents': documents,
    'symptoms': symptoms,
    'questions': questions,
    'reminder_minutes': reminderMinutes,
  };

  factory Appointment.fromMap(Map<String, Object?> map) => Appointment(
    id: map['id']! as String,
    date: DateTime.parse(map['date']! as String),
    reason: map['reason']! as String,
    provider: map['provider']! as String,
    documents: map['documents']! as String,
    symptoms: map['symptoms']! as String,
    questions: map['questions']! as String,
    reminderMinutes: (map['reminder_minutes'] as num?)?.toInt() ?? -1,
  );
}

class Medication {
  const Medication({
    required this.id,
    required this.name,
    this.strength = '',
    this.dose = '',
    this.schedule = '',
    this.notes = '',
    this.active = true,
    this.times = const [],
    this.reminderMinutes = -1,
  });

  final String id;
  final String name;
  final String strength;
  final String dose;
  final String schedule;
  final String notes;
  final bool active;

  /// Times of day the medication is taken, as 24-hour "HH:mm" strings.
  final List<String> times;

  /// Minutes before each time in [times] to show a reminder. -1 means none.
  final int reminderMinutes;

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'strength': strength,
    'dose': dose,
    'schedule': schedule,
    'notes': notes,
    'active': active ? 1 : 0,
    'times': times.join(','),
    'reminder_minutes': reminderMinutes,
  };

  factory Medication.fromMap(Map<String, Object?> map) => Medication(
    id: map['id']! as String,
    name: map['name']! as String,
    strength: map['strength']! as String,
    dose: map['dose']! as String,
    schedule: map['schedule']! as String,
    notes: map['notes']! as String,
    active: map['active'] == 1,
    times: ((map['times'] as String?) ?? '')
        .split(',')
        .where((value) => value.trim().isNotEmpty)
        .toList(),
    reminderMinutes: (map['reminder_minutes'] as num?)?.toInt() ?? -1,
  );
}

class HealthLogEntry {
  const HealthLogEntry({
    required this.id,
    required this.occurredAt,
    required this.text,
    this.flagged = false,
  });

  final String id;
  final DateTime occurredAt;
  final String text;
  final bool flagged;

  Map<String, Object?> toMap() => {
    'id': id,
    'occurred_at': occurredAt.toIso8601String(),
    'text': text,
    'flagged': flagged ? 1 : 0,
  };

  factory HealthLogEntry.fromMap(Map<String, Object?> map) => HealthLogEntry(
    id: map['id']! as String,
    occurredAt: DateTime.parse(map['occurred_at']! as String),
    text: map['text']! as String,
    flagged: map['flagged'] == 1,
  );
}

class Measurement {
  const Measurement({
    required this.id,
    required this.measuredAt,
    required this.type,
    required this.value,
    required this.unit,
    this.context = '',
  });

  final String id;
  final DateTime measuredAt;
  final String type;
  final String value;
  final String unit;
  final String context;

  /// Keep legacy "120/80" records compatible without a database migration.
  int? get systolic => type == 'Blood pressure'
      ? int.tryParse(value.split('/').first.trim())
      : null;
  int? get diastolic => type == 'Blood pressure' && value.split('/').length == 2
      ? int.tryParse(value.split('/')[1].trim())
      : null;

  Map<String, Object?> toMap() => {
    'id': id,
    'measured_at': measuredAt.toIso8601String(),
    'type': type,
    'value': value,
    'unit': unit,
    'context': context,
  };

  factory Measurement.fromMap(Map<String, Object?> map) => Measurement(
    id: map['id']! as String,
    measuredAt: DateTime.parse(map['measured_at']! as String),
    type: map['type']! as String,
    value: map['value']! as String,
    unit: map['unit']! as String,
    context: map['context']! as String,
  );
}
