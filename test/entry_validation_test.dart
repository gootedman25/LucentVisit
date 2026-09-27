import 'package:lucentvisit/src/models/entry_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? validate(
    String type,
    String value, {
    String unit = 'mg/dL',
    String top = '',
    String bottom = '',
  }) => measurementEntryError(
    type: type,
    value: value,
    unit: unit,
    systolic: top,
    diastolic: bottom,
  );

  test('blood pressure requires two positive whole numbers', () {
    expect(validate('Blood pressure', '', top: '120', bottom: '80'), isNull);
    expect(validate('Blood pressure', '', top: '120'), isNotNull);
    expect(
      validate('Blood pressure', '', top: '120.5', bottom: '80'),
      isNotNull,
    );
  });
  test('numeric entries require finite numbers and correct unit', () {
    expect(validate('Blood sugar', 'NaN'), isNotNull);
    expect(validate('Weight', '-5'), isNotNull);
    expect(validate('Temperature', '-5', unit: '°C'), isNull);
    expect(validate('Blood sugar', '95', unit: ''), isNotNull);
    expect(validate('Oxygen saturation', '101', unit: '%'), isNotNull);
  });
  test('non-daily schedules cannot silently repeat reminders daily', () {
    expect(supportsDailyMedicationReminders('Once weekly'), isFalse);
    expect(supportsDailyMedicationReminders('Every other day'), isFalse);
    expect(supportsDailyMedicationReminders('As needed'), isFalse);
    expect(supportsDailyMedicationReminders('Once daily'), isTrue);
  });
}
