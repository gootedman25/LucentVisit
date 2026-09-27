import 'package:lucentvisit/src/ai/ai_assistant_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const assistant = AiAssistantService();

  test('explainer returns plain-language sections', () async {
    final result = await assistant.explain(
      'Your appointment is scheduled for 9/12/2026. Bring your insurance card.',
    );

    expect(result.summary, contains('appointment'));
    expect(result.importantDetails, isNotEmpty);
    expect(result.questionsToAsk, isNotEmpty);
    expect(result.cautions.join(' '), contains('not medical advice'));
  });

  test('draft creator detects appointment and measurement text', () async {
    final drafts = await assistant.createDrafts(
      'Follow-up appointment 9/12/2026 at 2 PM. Blood sugar 120 mg/dL before breakfast.',
    );

    expect(drafts.any((draft) => draft.appointment != null), isTrue);
    final measurement = drafts
        .firstWhere((draft) => draft.measurement != null)
        .measurement!;
    expect(measurement.value, '120');
    expect(measurement.unit, 'mg/dL');
  });

  test(
    'draft creator does not turn impossible dates into rolled dates',
    () async {
      final drafts = await assistant.createDrafts(
        'Appointment 2/31/2026 at 8 AM',
      );

      final appointment = drafts.first.appointment!;
      expect(appointment.date.month, isNot(3));
    },
  );
}
