import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucentvisit/src/ai/ai_assistant_service.dart';
import 'package:lucentvisit/src/app.dart';
import 'package:lucentvisit/src/data/lucentvisit_repository.dart';
import 'package:lucentvisit/src/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reviewed AI appointment draft can be saved to Visits', (
    tester,
  ) async {
    final repository = _FakeRepository();
    final service = AiAssistantService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'drafts': [
              {
                'type': 'appointment',
                'values': [
                  {'field': 'date', 'value': '2030-10-17'},
                  {'field': 'time', 'value': '14:30'},
                  {'field': 'reason', 'value': 'Follow-up visit'},
                  {'field': 'provider', 'value': 'Dr. Taylor'},
                  {'field': 'reminder_minutes', 'value': '-1'},
                ],
                'evidence': 'Follow-up on October 17 at 2:30 PM.',
                'missing_required': <String>[],
              },
            ],
          }),
          200,
        ),
      ),
      baseUrl: 'https://example.test',
      appCheckTokenProvider: () async => 'test-token',
    );
    await tester.pumpWidget(
      LucentVisitApp(repository: repository, aiService: service),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explain text'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create organizer drafts').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Follow-up on October 17 at 2:30 PM.',
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -320));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Save to Visits'), findsOneWidget);
    expect(repository._appointments, isEmpty);
    await tester.tap(find.text('Save to Visits'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(repository._appointments, hasLength(1));
    expect(repository._appointments.single.reason, 'Follow-up visit');
    expect(repository._appointments.single.provider, 'Dr. Taylor');
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('blood pressure edits separate top and bottom numbers', (
    tester,
  ) async {
    final repository = _FakeRepository(
      measurements: [
        Measurement(
          id: 'pressure-1',
          measuredAt: DateTime(2026, 9, 1),
          type: 'Blood pressure',
          value: '120/80',
          unit: 'mmHg',
        ),
      ],
    );
    await tester.pumpWidget(LucentVisitApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vitals'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blood pressure'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    expect(tester.widget<TextField>(fields.at(0)).controller!.text, '120');
    expect(tester.widget<TextField>(fields.at(1)).controller!.text, '80');
    await tester.enterText(fields.at(0), '125');
    await tester.enterText(fields.at(1), '85');
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(repository._measurements.single.id, 'pressure-1');
    expect(repository._measurements.single.value, '125/85');
  });

  testWidgets('empty notes show an error without dismissing the form', (
    tester,
  ) async {
    await tester.pumpWidget(LucentVisitApp(repository: _FakeRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add log entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Write a note before saving.'), findsOneWidget);
    expect(find.text('New log entry'), findsOneWidget);
  });
  testWidgets('text helper page has a back button that returns Home', (
    tester,
  ) async {
    await tester.pumpWidget(LucentVisitApp(repository: _FakeRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('section-back-button')), findsOneWidget);
    expect(find.text('AI text helper'), findsOneWidget);

    await tester.tap(find.byKey(const Key('section-back-button')));
    await tester.pumpAndSettle();

    expect(find.text('Where would you like to go?'), findsOneWidget);
  });

  testWidgets('tapping the LucentVisit logo returns Home', (tester) async {
    await tester.pumpWidget(LucentVisitApp(repository: _FakeRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-logo-button')));
    await tester.pumpAndSettle();

    expect(find.text('Where would you like to go?'), findsOneWidget);
  });

  testWidgets('system back returns a section to Home before exiting', (
    tester,
  ) async {
    await tester.pumpWidget(LucentVisitApp(repository: _FakeRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Where would you like to go?'), findsOneWidget);
  });

  testWidgets('existing entries expose an edit flow', (tester) async {
    final repository = _FakeRepository(
      appointments: [
        Appointment(
          id: 'appointment-1',
          date: DateTime(2026, 9, 10, 9),
          reason: 'Annual checkup',
        ),
      ],
      medications: const [
        Medication(id: 'medication-1', name: 'Aspirin', strength: '81 mg'),
      ],
      healthLog: [
        HealthLogEntry(
          id: 'log-1',
          occurredAt: DateTime(2026, 9, 1),
          text: 'Original note',
        ),
      ],
      measurements: [
        Measurement(
          id: 'measurement-1',
          measuredAt: DateTime(2026, 9, 1),
          type: 'Weight',
          value: '150',
          unit: 'lb',
        ),
      ],
    );
    await tester.pumpWidget(LucentVisitApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Visits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annual checkup'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Edit appointment'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Edit appointment'));
    await tester.pumpAndSettle();
    expect(find.text('Edit appointment'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meds'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aspirin 81 mg'));
    await tester.pumpAndSettle();
    expect(find.text('Edit medication'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Original note'));
    await tester.pumpAndSettle();
    expect(find.text('Edit log entry'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vitals'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weight'));
    await tester.pumpAndSettle();
    expect(find.text('Edit measurement'), findsOneWidget);
  });

  testWidgets('health log entry can be updated and deleted', (tester) async {
    final repository = _FakeRepository(
      healthLog: [
        HealthLogEntry(
          id: 'log-1',
          occurredAt: DateTime(2026, 9, 1),
          text: 'Original note',
        ),
      ],
    );
    await tester.pumpWidget(LucentVisitApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Original note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Updated note');
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(find.text('Updated note'), findsOneWidget);
    expect(repository._healthLog.single.id, 'log-1');

    await tester.tap(find.text('Updated note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repository._healthLog, isEmpty);
    expect(find.text('Your log is empty'), findsOneWidget);
  });
}

class _FakeRepository implements LucentVisitRepository {
  _FakeRepository({
    List<Appointment> appointments = const [],
    List<Medication> medications = const [],
    List<HealthLogEntry> healthLog = const [],
    List<Measurement> measurements = const [],
  }) : _appointments = [...appointments],
       _medications = [...medications],
       _healthLog = [...healthLog],
       _measurements = [...measurements];

  final List<Appointment> _appointments;
  final List<Medication> _medications;
  final List<HealthLogEntry> _healthLog;
  final List<Measurement> _measurements;

  @override
  Future<List<Appointment>> appointments() async => [..._appointments];

  @override
  Future<void> deleteEverything() async {
    _appointments.clear();
    _medications.clear();
    _healthLog.clear();
    _measurements.clear();
  }

  @override
  Future<void> deleteAppointment(String id) async {
    _appointments.removeWhere((value) => value.id == id);
  }

  @override
  Future<void> deleteHealthLogEntry(String id) async {
    _healthLog.removeWhere((value) => value.id == id);
  }

  @override
  Future<void> deleteMeasurement(String id) async {
    _measurements.removeWhere((value) => value.id == id);
  }

  @override
  Future<void> deleteMedication(String id) async {
    _medications.removeWhere((value) => value.id == id);
  }

  @override
  Future<List<HealthLogEntry>> healthLog() async => [..._healthLog];

  @override
  Future<List<Measurement>> measurements() async => [..._measurements];

  @override
  Future<List<Medication>> medications() async => [..._medications];

  @override
  Future<void> saveAppointment(Appointment value) async {
    _upsert(_appointments, value, (item) => item.id);
  }

  @override
  Future<void> saveHealthLogEntry(HealthLogEntry value) async {
    _upsert(_healthLog, value, (item) => item.id);
  }

  @override
  Future<void> saveMeasurement(Measurement value) async {
    _upsert(_measurements, value, (item) => item.id);
  }

  @override
  Future<void> saveMedication(Medication value) async {
    _upsert(_medications, value, (item) => item.id);
  }

  @override
  Future<void> saveSetting(String key, String value) async {}

  @override
  Future<String?> setting(String key) async => null;

  void _upsert<T>(List<T> values, T value, String Function(T) idOf) {
    final index = values.indexWhere((item) => idOf(item) == idOf(value));
    if (index == -1) {
      values.add(value);
    } else {
      values[index] = value;
    }
  }
}
