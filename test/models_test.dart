import 'package:lucentvisit/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('medication round-trips through database map', () {
    const original = Medication(
      id: 'med-1',
      name: 'Example medication',
      strength: '10 mg',
      dose: '1 tablet',
      schedule: 'Every morning',
    );
    final restored = Medication.fromMap(original.toMap());
    expect(restored.name, original.name);
    expect(restored.active, isTrue);
  });

  test('generated IDs are unique', () {
    expect(newId(), isNot(equals(newId())));
  });
}
