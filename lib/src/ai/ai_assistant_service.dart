import 'package:flutter/material.dart';

import '../models/models.dart';

class AiExplanation {
  const AiExplanation({
    required this.summary,
    required this.importantDetails,
    required this.questionsToAsk,
    required this.cautions,
  });

  final String summary;
  final List<String> importantDetails;
  final List<String> questionsToAsk;
  final List<String> cautions;
}

enum AiDraftType { appointment, medication, healthLog, measurement }

class AiDraft {
  const AiDraft({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.reason,
    this.appointment,
    this.medication,
    this.healthLogEntry,
    this.measurement,
  });

  final AiDraftType type;
  final String title;
  final String subtitle;
  final String reason;
  final Appointment? appointment;
  final Medication? medication;
  final HealthLogEntry? healthLogEntry;
  final Measurement? measurement;
}

class AiAssistantService {
  const AiAssistantService();

  Future<AiExplanation> explain(String input) async {
    final text = input.trim();
    final lines = _meaningfulLines(text);
    final keyLines = lines.where(_looksImportant).take(6).toList();
    final questions = <String>[
      if (_containsAny(text, ['denied', 'appeal', 'prior authorization']))
        'What is the next step if I disagree with this decision?',
      if (_containsAny(text, ['bill', 'balance', 'claim', 'coverage']))
        'Can you explain what I owe versus what insurance may cover?',
      if (_containsAny(text, ['referral', 'specialist']))
        'Do I need a referral before scheduling this visit?',
      if (_containsAny(text, ['lab', 'test', 'imaging', 'x-ray', 'mri']))
        'Do I need to fast, bring anything, or schedule follow-up for these results?',
      'Who should I contact if I do not understand this document?',
    ];

    return AiExplanation(
      summary: _summaryFor(text, lines),
      importantDetails: keyLines.isEmpty
          ? [
              'No obvious dates, deadlines, phone numbers, or required actions were detected.',
            ]
          : keyLines,
      questionsToAsk: questions,
      cautions: const [
        'LucentVisit can help organize confusing text, but it is not medical advice.',
        'Confirm important medical, insurance, billing, or medication decisions with the appropriate professional.',
      ],
    );
  }

  Future<List<AiDraft>> createDrafts(String input) async {
    // One passage may describe several entry types, so classification checks are
    // intentionally independent rather than an if/else chain. Nothing is saved
    // by this service; the screen requires a separate user-approved save action.
    final text = input.trim();
    if (text.isEmpty) return const [];

    final drafts = <AiDraft>[];
    final now = DateTime.now();
    final lower = text.toLowerCase();

    if (_containsAny(lower, [
      'appointment',
      'appt',
      'visit',
      'follow up',
      'follow-up',
      'doctor',
      'clinic',
    ])) {
      // These placeholders complete a draft when the text omits a date or time.
      final date = _extractDate(text, now) ?? now.add(const Duration(days: 1));
      final time = _extractTime(text) ?? const TimeOfDay(hour: 9, minute: 0);
      final when = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      final provider = _extractProvider(text);
      final appointment = Appointment(
        id: newId(),
        date: when,
        reason: _extractReason(text, fallback: 'Appointment'),
        provider: provider,
        documents: _containsAny(lower, ['insurance card', 'id', 'photo id'])
            ? 'Bring insurance card and photo ID.'
            : '',
        symptoms: _containsAny(lower, ['symptom', 'pain', 'dizzy', 'nausea'])
            ? text
            : '',
        questions: 'Ask what to do next and whether any follow-up is needed.',
        reminderMinutes: _extractReminderMinutes(lower, defaultValue: 1440),
      );
      drafts.add(
        AiDraft(
          type: AiDraftType.appointment,
          title: appointment.reason,
          subtitle:
              '${_weekdayName(appointment.date)}, ${_shortDate(appointment.date)} at ${_formatTimeOfDay(TimeOfDay.fromDateTime(appointment.date))}',
          reason: 'Detected appointment-like language.',
          appointment: appointment,
        ),
      );
    }

    if (_containsAny(lower, [
      'take ',
      'tablet',
      'capsule',
      'mg',
      'medication',
      'medicine',
      'pill',
    ])) {
      final time = _extractTime(text);
      final medication = Medication(
        id: newId(),
        name: _extractMedicationName(text),
        strength: _extractStrength(text),
        dose: _containsAny(lower, ['2 tablet', 'two tablet'])
            ? '2 tablets'
            : _containsAny(lower, ['1 tablet', 'one tablet'])
            ? '1 tablet'
            : '',
        schedule: _extractSchedule(lower),
        times: time == null ? const [] : [_timeToStorage(time)],
        reminderMinutes: _extractReminderMinutes(lower, defaultValue: -1),
      );
      drafts.add(
        AiDraft(
          type: AiDraftType.medication,
          title: [
            medication.name,
            medication.strength,
          ].where((part) => part.isNotEmpty).join(' '),
          subtitle: [
            medication.dose,
            medication.schedule,
          ].where((part) => part.isNotEmpty).join(' • '),
          reason: 'Detected medication-like language.',
          medication: medication,
        ),
      );
    }

    if (_containsAny(lower, [
      'blood sugar',
      'glucose',
      'blood pressure',
      'weight',
      'temperature',
      'heart rate',
      'oxygen',
    ])) {
      final measurement = Measurement(
        id: newId(),
        measuredAt: _extractDate(text, now) ?? now,
        type: _extractMeasurementType(lower),
        value: _extractMeasurementValue(text),
        unit: _extractMeasurementUnit(lower),
        context: _extractMeasurementContext(lower),
      );
      if (measurement.value.isNotEmpty) {
        drafts.add(
          AiDraft(
            type: AiDraftType.measurement,
            title: measurement.type,
            subtitle:
                '${measurement.value} ${measurement.unit}${measurement.context.isEmpty ? '' : ' • ${measurement.context}'}',
            reason: 'Detected a trackable measurement.',
            measurement: measurement,
          ),
        );
      }
    }

    if (_containsAny(lower, [
      'felt',
      'symptom',
      'pain',
      'dizzy',
      'nausea',
      'headache',
      'tired',
      'fatigue',
      'rash',
    ])) {
      final entry = HealthLogEntry(
        id: newId(),
        occurredAt: _extractDate(text, now) ?? now,
        text: text,
        flagged: _containsAny(lower, [
          'ask',
          'doctor',
          'appointment',
          'visit',
          'concern',
        ]),
      );
      drafts.add(
        AiDraft(
          type: AiDraftType.healthLog,
          title: entry.flagged
              ? 'Flagged health log entry'
              : 'Health log entry',
          subtitle: entry.text,
          reason: 'Detected symptom or health-journal language.',
          healthLogEntry: entry,
        ),
      );
    }

    if (drafts.isEmpty) {
      drafts.add(
        AiDraft(
          type: AiDraftType.healthLog,
          title: 'General note',
          subtitle: text,
          reason:
              'No specific entry type was obvious, so this can be saved as a log note.',
          healthLogEntry: HealthLogEntry(
            id: newId(),
            occurredAt: now,
            text: text,
            flagged: false,
          ),
        ),
      );
    }

    return drafts;
  }

  String _summaryFor(String text, List<String> lines) {
    if (text.isEmpty) {
      return 'Paste text from a letter or notice to get a plain-language explanation.';
    }
    final firstLine = lines.isEmpty ? text : lines.first;
    if (_containsAny(text, ['denied', 'appeal'])) {
      return 'This appears to include an insurance or coverage decision. Look for the reason, appeal deadline, and who to contact.';
    }
    if (_containsAny(text, ['appointment', 'scheduled', 'visit'])) {
      return 'This appears to include appointment instructions. Look for the date, time, location, and what to bring.';
    }
    if (_containsAny(text, ['lab', 'test', 'result'])) {
      return 'This appears to mention tests or results. Use it to prepare follow-up questions for your provider.';
    }
    return firstLine.length > 220
        ? '${firstLine.substring(0, 220)}…'
        : firstLine;
  }

  List<String> _meaningfulLines(String text) => text
      .split(RegExp(r'[\n\r]+'))
      .map((line) => line.trim())
      .where((line) => line.length > 2)
      .toList();

  bool _looksImportant(String line) {
    final lower = line.toLowerCase();
    return RegExp(r'\b\d{1,2}[/-]\d{1,2}([/-]\d{2,4})?\b').hasMatch(lower) ||
        RegExp(r'\b\d{3}[-.]\d{3}[-.]\d{4}\b').hasMatch(lower) ||
        _containsAny(lower, [
          'deadline',
          'due',
          'bring',
          'call',
          'schedule',
          'appointment',
          'denied',
          'approved',
          'appeal',
          'authorization',
          'referral',
        ]);
  }

  bool _containsAny(String text, List<String> needles) {
    final lower = text.toLowerCase();
    return needles.any(lower.contains);
  }

  DateTime? _extractDate(String text, DateTime now) {
    // Deliberately narrow parser: today/tomorrow and US-style numeric dates.
    final lower = text.toLowerCase();
    if (lower.contains('tomorrow')) return now.add(const Duration(days: 1));
    if (lower.contains('today')) return now;
    final numeric = RegExp(
      r'\b(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?\b',
    ).firstMatch(text);
    if (numeric != null) {
      final month = int.tryParse(numeric.group(1)!);
      final day = int.tryParse(numeric.group(2)!);
      var year = int.tryParse(numeric.group(3) ?? '${now.year}') ?? now.year;
      if (year < 100) year += 2000;
      if (month != null &&
          day != null &&
          month >= 1 &&
          month <= 12 &&
          day >= 1 &&
          day <= 31) {
        final parsed = DateTime(year, month, day);
        if (parsed.year == year && parsed.month == month && parsed.day == day) {
          return parsed;
        }
      }
    }
    return null;
  }

  TimeOfDay? _extractTime(String text) {
    final match = RegExp(
      r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!) ?? 0;
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    final period = match.group(3)!.toLowerCase();
    if (period.startsWith('p') && hour != 12) hour += 12;
    if (period.startsWith('a') && hour == 12) hour = 0;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  int _extractReminderMinutes(String lower, {required int defaultValue}) {
    if (lower.contains('no reminder')) return -1;
    if (lower.contains('1 day') || lower.contains('day before')) return 1440;
    if (lower.contains('2 hour')) return 120;
    if (lower.contains('1 hour') || lower.contains('hour before')) return 60;
    if (lower.contains('30 min')) return 30;
    if (lower.contains('15 min')) return 15;
    return defaultValue;
  }

  String _extractProvider(String text) {
    final match = RegExp(
      r'\b(?:with|at)\s+([A-Z][A-Za-z.\s]{2,40})',
    ).firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }

  String _extractReason(String text, {required String fallback}) {
    final lower = text.toLowerCase();
    if (lower.contains('follow')) return 'Follow-up visit';
    if (lower.contains('lab') || lower.contains('test')) {
      return 'Lab work or test results';
    }
    if (lower.contains('medication') || lower.contains('refill')) {
      return 'Medication review or refill';
    }
    if (lower.contains('annual') || lower.contains('physical')) {
      return 'Annual physical';
    }
    return fallback;
  }

  String _extractMedicationName(String text) {
    // This heuristic only looks near "take" or a strength such as 10 mg.
    final words = text.split(RegExp(r'\s+'));
    final mgIndex = words.indexWhere(
      (word) => RegExp(r'\d+\s*mg', caseSensitive: false).hasMatch(word),
    );
    if (mgIndex > 0) {
      return words[mgIndex - 1].replaceAll(RegExp(r'[^A-Za-z-]'), '');
    }
    final takeIndex = words.indexWhere(
      (word) => word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '') == 'take',
    );
    if (takeIndex >= 0 && takeIndex + 1 < words.length) {
      return words[takeIndex + 1].replaceAll(RegExp(r'[^A-Za-z-]'), '');
    }
    return 'Medication';
  }

  String _extractStrength(String text) {
    final match = RegExp(
      r'\b(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml|units?)\b',
      caseSensitive: false,
    ).firstMatch(text);
    return match == null ? '' : '${match.group(1)} ${match.group(2)}';
  }

  String _extractSchedule(String lower) {
    if (lower.contains('twice')) return 'Twice daily';
    if (lower.contains('three times')) return 'Three times daily';
    if (lower.contains('weekly')) return 'Once weekly';
    if (lower.contains('bedtime')) return 'Bedtime';
    if (lower.contains('morning')) return 'Morning';
    if (lower.contains('evening')) return 'Evening';
    if (lower.contains('daily')) return 'Once daily';
    return '';
  }

  String _extractMeasurementType(String lower) {
    if (lower.contains('blood pressure')) return 'Blood pressure';
    if (lower.contains('blood sugar') || lower.contains('glucose')) {
      return 'Blood sugar';
    }
    if (lower.contains('weight')) return 'Weight';
    if (lower.contains('temperature')) return 'Temperature';
    if (lower.contains('heart rate')) return 'Heart rate';
    if (lower.contains('oxygen')) return 'Oxygen saturation';
    return 'Measurement';
  }

  String _extractMeasurementValue(String text) {
    // Search only the clause following the measurement keyword and remove dates
    // first, reducing the chance that a date is mistaken for a reading.
    final lower = text.toLowerCase();
    final keyword = [
      'blood pressure',
      'blood sugar',
      'glucose',
      'weight',
      'temperature',
      'heart rate',
      'oxygen',
    ].firstWhere(lower.contains, orElse: () => '');
    final scopedText = keyword.isEmpty
        ? text
        : text
              .substring(lower.indexOf(keyword))
              .split(RegExp(r'[.;\n\r]'))
              .first;
    if (keyword == 'blood pressure') {
      final pressure = RegExp(r'\b\d{2,3}/\d{2,3}\b').firstMatch(scopedText);
      if (pressure != null) return pressure.group(0)!;
    }
    final withoutDates = scopedText.replaceAll(
      RegExp(r'\b\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?\b'),
      ' ',
    );
    final match = RegExp(r'\b\d+(?:\.\d+)?\b').firstMatch(withoutDates);
    return match?.group(0) ?? '';
  }

  String _extractMeasurementUnit(String lower) {
    if (lower.contains('mmhg')) return 'mmHg';
    if (lower.contains('mg/dl') ||
        lower.contains('blood sugar') ||
        lower.contains('glucose')) {
      return 'mg/dL';
    }
    if (lower.contains('mmol/l')) return 'mmol/L';
    if (lower.contains('bpm') || lower.contains('heart rate')) return 'bpm';
    if (lower.contains('%') || lower.contains('oxygen')) return '%';
    if (lower.contains('kg')) return 'kg';
    if (lower.contains('lb')) return 'lb';
    if (lower.contains('°c') || lower.contains(' c')) return '°C';
    if (lower.contains('°f') || lower.contains(' f')) return '°F';
    return '';
  }

  String _extractMeasurementContext(String lower) {
    if (lower.contains('before breakfast')) return 'Before breakfast';
    if (lower.contains('after breakfast')) return 'After breakfast';
    if (lower.contains('before lunch')) return 'Before lunch';
    if (lower.contains('after lunch')) return 'After lunch';
    if (lower.contains('before dinner')) return 'Before dinner';
    if (lower.contains('after dinner')) return 'After dinner';
    if (lower.contains('bedtime')) return 'Bedtime';
    if (lower.contains('exercise')) return 'After exercise';
    return '';
  }

  String _shortDate(DateTime value) =>
      '${value.month}/${value.day}/${value.year}';

  String _weekdayName(DateTime value) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][value.weekday - 1];

  String _formatTimeOfDay(TimeOfDay value) {
    final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  String _timeToStorage(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
