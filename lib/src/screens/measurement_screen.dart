import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/models.dart';
import '../models/entry_validation.dart';
import '../widgets/common.dart';
import '../widgets/entry_fields.dart';

const Map<String, List<String>> _measurementUnits = {
  'Blood sugar': ['mg/dL', 'mmol/L'],
  'Blood pressure': ['mmHg'],
  'Weight': ['lb', 'kg'],
  'Temperature': ['°F', '°C'],
  'Heart rate': ['bpm'],
  'Oxygen saturation': ['%'],
};

const List<String> _measurementContexts = [
  'Before breakfast',
  'After breakfast',
  'Before lunch',
  'After lunch',
  'Before dinner',
  'After dinner',
  'Bedtime',
  'After exercise',
  'When symptoms happened',
];

class MeasurementScreen extends StatelessWidget {
  const MeasurementScreen({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) => Column(
      children: [
        const ScreenIntro(
          title: 'Measurements',
          body:
              'Record values without interpretation. Ask a healthcare professional what your values mean.',
        ),
        Expanded(
          child: state.measurements.isEmpty
              ? const EmptyState(
                  icon: Icons.monitor_heart_outlined,
                  title: 'No measurements yet',
                  body:
                      'You can manually record blood sugar, blood pressure, weight, or another value.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
                  children: state.measurements
                      .map(
                        (value) => SummaryCard(
                          icon: Icons.monitor_heart_outlined,
                          title: value.type,
                          subtitle:
                              '${weekdayName(value.measuredAt)}, ${shortDate(value.measuredAt)} at ${formatTimeOfDay(TimeOfDay.fromDateTime(value.measuredAt))}${value.context.isEmpty ? '' : ' • ${value.context}'}',
                          trailing: Text(
                            '${value.value} ${value.unit}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          onTap: () => _edit(context, value),
                        ),
                      )
                      .toList(),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: FilledButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.add),
              label: const Text('Add measurement'),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _edit(BuildContext context, [Measurement? existing]) async {
    final type = TextEditingController(text: existing?.type);
    final value = TextEditingController(text: existing?.value);
    final unit = TextEditingController(text: existing?.unit);
    final measurementContext = TextEditingController(text: existing?.context);
    final systolic = TextEditingController(
      text: existing?.systolic?.toString(),
    );
    final diastolic = TextEditingController(
      text: existing?.diastolic?.toString(),
    );
    String? error;
    var measuredAt = existing?.measuredAt ?? DateTime.now();
    try {
      final route = DialogRoute<EntryDialogAction>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            final units =
                _measurementUnits[type.text] ??
                const ['mg/dL', 'mmHg', 'lb', 'kg', 'bpm', '%'];
            return AlertDialog(
              title: EntryDialogTitle(
                title: existing == null
                    ? 'Add measurement'
                    : 'Edit measurement',
                error: error,
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    DateDropdownEntry(
                      value: measuredAt,
                      label: 'Measurement date',
                      yearCount: 3,
                      onChanged: (date) =>
                          setDialogState(() => measuredAt = date),
                    ),
                    DropdownEntry(
                      controller: type,
                      label: 'Type',
                      options: _measurementUnits.keys.toList(),
                      otherHint: 'Enter measurement type',
                      onChanged: (selected) => setDialogState(() {
                        final choices = _measurementUnits[selected];
                        unit.text = choices?.length == 1 ? choices!.single : '';
                      }),
                    ),
                    TimeDropdownEntry(
                      value: TimeOfDay.fromDateTime(measuredAt),
                      label: 'Measurement time',
                      onChanged: (time) => setDialogState(
                        () => measuredAt = DateTime(
                          measuredAt.year,
                          measuredAt.month,
                          measuredAt.day,
                          time.hour,
                          time.minute,
                        ),
                      ),
                    ),
                    if (type.text == 'Blood pressure') ...[
                      const Text(
                        'Copy both numbers from your monitor. Unit: mmHg.',
                      ),
                      const SizedBox(height: 12),
                      TextEntry(
                        controller: systolic,
                        label: 'Systolic (top number)',
                        keyboardType: TextInputType.number,
                      ),
                      TextEntry(
                        controller: diastolic,
                        label: 'Diastolic (bottom number)',
                        keyboardType: TextInputType.number,
                      ),
                    ] else
                      TextEntry(
                        controller: value,
                        label: 'Value',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    if (type.text != 'Blood pressure')
                      DropdownEntry(
                        controller: unit,
                        label: 'Unit',
                        options: units,
                      ),
                    DropdownEntry(
                      controller: measurementContext,
                      label: 'Context',
                      options: _measurementContexts,
                      otherHint: 'Enter context',
                    ),
                  ],
                ),
              ),
              actions: [
                if (existing != null)
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, EntryDialogAction.delete),
                    child: const Text('Delete'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final message = measurementEntryError(
                      type: type.text,
                      value: value.text,
                      unit: unit.text,
                      systolic: systolic.text,
                      diastolic: diastolic.text,
                    );
                    if (message != null) {
                      setDialogState(() => error = message);
                    } else if (measuredAt.isAfter(DateTime.now())) {
                      setDialogState(
                        () => error =
                            'Choose when this reading was actually taken, not a future time.',
                      );
                    } else {
                      Navigator.pop(context, EntryDialogAction.save);
                    }
                  },
                  child: Text(existing == null ? 'Save' : 'Update'),
                ),
              ],
            );
          },
        ),
      );
      final action = await Navigator.of(
        context,
        rootNavigator: true,
      ).push(route);
      await route.completed;
      if (action == EntryDialogAction.delete && existing != null) {
        if (context.mounted &&
            await confirmEntryDeletion(context, 'measurement')) {
          await state.deleteMeasurement(existing.id);
        }
      } else if (action == EntryDialogAction.save &&
          type.text.trim().isNotEmpty) {
        await state.addMeasurement(
          Measurement(
            id: existing?.id ?? newId(),
            measuredAt: measuredAt,
            type: type.text.trim(),
            value: type.text == 'Blood pressure'
                ? '${systolic.text.trim()}/${diastolic.text.trim()}'
                : value.text.trim(),
            unit: type.text == 'Blood pressure' ? 'mmHg' : unit.text.trim(),
            context: measurementContext.text.trim(),
          ),
        );
      }
    } finally {
      type.dispose();
      value.dispose();
      unit.dispose();
      measurementContext.dispose();
      systolic.dispose();
      diastolic.dispose();
    }
  }
}
