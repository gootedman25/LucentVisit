/// Returns whether the app can translate a schedule into repeating daily
/// notifications. Less regular schedules stay recordable but are not scheduled.
bool supportsDailyMedicationReminders(String schedule) => const {
  'Morning',
  'Afternoon',
  'Evening',
  'Bedtime',
  'Morning and evening',
  'With meals',
  'Once daily',
  'Twice daily',
  'Three times daily',
}.contains(schedule);

String? measurementEntryError({
  required String type,
  required String value,
  required String unit,
  required String systolic,
  required String diastolic,
}) {
  // These rules validate that a reading can be stored and that its unit matches
  // its type. They intentionally do not decide whether a value is medically
  // normal, safe, or urgent.
  if (type.trim().isEmpty) return 'Choose a measurement type.';
  if (type == 'Blood pressure') {
    final top = int.tryParse(systolic.trim());
    final bottom = int.tryParse(diastolic.trim());
    if (top == null || bottom == null || top <= 0 || bottom <= 0) {
      return 'Enter both systolic (top) and diastolic (bottom) as positive whole numbers.';
    }
    return null;
  }
  if (value.trim().isEmpty) return 'Enter the recorded value.';
  const numericTypes = {
    'Blood sugar',
    'Weight',
    'Temperature',
    'Heart rate',
    'Oxygen saturation',
  };
  if (numericTypes.contains(type)) {
    final number = double.tryParse(value.trim());
    if (number == null ||
        !number.isFinite ||
        (type != 'Temperature' && number <= 0)) {
      return 'Enter a valid ${type == 'Temperature' ? '' : 'positive '}number.';
    }
    if (type == 'Oxygen saturation' && number > 100) {
      return 'A percentage cannot be greater than 100.';
    }
    if (unit.trim().isEmpty) return 'Choose the unit shown on your device.';
    const allowedUnits = {
      'Blood sugar': ['mg/dL', 'mmol/L'],
      'Weight': ['lb', 'kg'],
      'Temperature': ['°F', '°C'],
      'Heart rate': ['bpm'],
      'Oxygen saturation': ['%'],
    };
    if (!allowedUnits[type]!.contains(unit.trim())) {
      return 'Choose a unit that matches this measurement type.';
    }
  }
  return null;
}
