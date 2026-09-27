import 'package:lucentvisit/src/widgets/common.dart';
import 'package:lucentvisit/src/widgets/entry_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('date and time controls retain older years and exact minutes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                DateDropdownEntry(
                  value: DateTime(2020, 2, 29),
                  onChanged: (_) {},
                ),
                TimeDropdownEntry(
                  value: const TimeOfDay(hour: 9, minute: 37),
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byKey(const ValueKey('year-2020-2-29')),
          )
          .initialValue,
      2020,
    );
    expect(
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byKey(const ValueKey('minute-9-37')),
          )
          .initialValue,
      37,
    );
  });
  group('timeFromStorage', () {
    test('parses a valid 24-hour time', () {
      expect(timeFromStorage('09:45'), const TimeOfDay(hour: 9, minute: 45));
    });

    test('rejects malformed and out-of-range values', () {
      expect(timeFromStorage('not-a-time'), isNull);
      expect(timeFromStorage('9:45'), isNull);
      expect(timeFromStorage('24:00'), isNull);
      expect(timeFromStorage('10:60'), isNull);
      expect(timeFromStorage('-1:30'), isNull);
    });
  });
}
