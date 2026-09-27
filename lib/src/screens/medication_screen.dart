import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/medication_catalog.dart';
import '../models/models.dart';
import '../models/entry_validation.dart';
import '../widgets/common.dart';
import '../widgets/entry_fields.dart';

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) => Column(
      children: [
        const ScreenIntro(
          title: 'Medication list',
          body:
              'Record exactly what the label says. LucentVisit does not check medications or doses.',
        ),
        Expanded(
          child: state.medications.isEmpty
              ? const EmptyState(
                  icon: Icons.medication,
                  title: 'No medications yet',
                  body: 'Add each medication from its label.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
                  children: state.medications
                      .map(
                        (value) => SummaryCard(
                          icon: Icons.medication_outlined,
                          title:
                              '${value.name}${value.strength.isEmpty ? '' : ' ${value.strength}'}',
                          subtitle: [
                            value.dose,
                            value.schedule,
                            value.times
                                .map((time) {
                                  final parsed = timeFromStorage(time);
                                  return parsed == null
                                      ? time
                                      : formatTimeOfDay(parsed);
                                })
                                .join(', '),
                          ].where((part) => part.isNotEmpty).join(' • '),
                          trailing: const Icon(Icons.edit_outlined),
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
              label: const Text('Add medication'),
            ),
          ),
        ),
      ],
    ),
  );

  static const Map<int, String> _reminderChoices = {
    -1: 'No reminder',
    0: 'At the scheduled time',
    5: '5 minutes before',
    10: '10 minutes before',
    15: '15 minutes before',
    30: '30 minutes before',
  };

  static List<TimeOfDay> _seedTimes(String schedule) {
    const seeds = <String, List<int>>{
      'Morning': [8],
      'Afternoon': [13],
      'Evening': [18],
      'Bedtime': [22],
      'Morning and evening': [8, 20],
      'With meals': [8, 12, 18],
      'Once daily': [8],
      'Twice daily': [8, 20],
      'Three times daily': [8, 14, 20],
      'Every other day': [8],
      'Once weekly': [8],
    };
    return (seeds[schedule] ?? const [])
        .map((hour) => TimeOfDay(hour: hour, minute: 0))
        .toList();
  }

  Future<void> _edit(BuildContext context, [Medication? existing]) async {
    final name = TextEditingController(text: existing?.name);
    final strength = TextEditingController(text: existing?.strength);
    final dose = TextEditingController(text: existing?.dose);
    final schedule = TextEditingController(text: existing?.schedule);
    final notes = TextEditingController(text: existing?.notes);
    var times =
        existing?.times.map(timeFromStorage).whereType<TimeOfDay>().toList() ??
        <TimeOfDay>[];
    var reminderMinutes = existing?.reminderMinutes ?? -1;
    String? error;
    try {
      final route = DialogRoute<EntryDialogAction>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            final knownStrengths = MedicationCatalog.strengthsFor(name.text);
            final strengthOptions = knownStrengths.isNotEmpty
                ? knownStrengths
                : MedicationCatalog.genericStrengths;
            return AlertDialog(
              title: EntryDialogTitle(
                title: existing == null ? 'Add medication' : 'Edit medication',
                error: error,
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      AutocompleteEntry(
                        controller: name,
                        label: 'Medication name',
                        optionsBuilder: MedicationCatalog.search,
                        onChanged: (_) => setState(() {}),
                        onSelected: (_) => setState(() {}),
                      ),
                      DropdownEntry(
                        controller: strength,
                        label: 'Strength',
                        options: strengthOptions,
                      ),
                      DropdownEntry(
                        controller: dose,
                        label: 'Dose',
                        options: MedicationCatalog.doseOptions,
                      ),
                      DropdownEntry(
                        controller: schedule,
                        label: 'When you take it',
                        options: MedicationCatalog.scheduleOptions,
                        onChanged: (value) =>
                            setState(() => times = _seedTimes(value)),
                      ),
                      const FormSectionLabel('Times you take it'),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var i = 0; i < times.length; i++)
                                InputChip(
                                  label: Text(formatTimeOfDay(times[i])),
                                  onPressed: () async {
                                    final picked = await _pickTimeDropdown(
                                      context,
                                      times[i],
                                    );
                                    if (picked != null) {
                                      setState(() => times[i] = picked);
                                    }
                                  },
                                  onDeleted: () =>
                                      setState(() => times.removeAt(i)),
                                ),
                              ActionChip(
                                avatar: const Icon(Icons.add, size: 18),
                                label: const Text('Add time'),
                                onPressed: () async {
                                  final picked = await _pickTimeDropdown(
                                    context,
                                    const TimeOfDay(hour: 8, minute: 0),
                                  );
                                  if (picked != null) {
                                    setState(() => times.add(picked));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      ReminderDropdown(
                        value: reminderMinutes,
                        choices: _reminderChoices,
                        onChanged: (value) =>
                            setState(() => reminderMinutes = value),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 14),
                        child: Text(
                          'Reminders repeat daily at the times you choose. Weekly, alternate-day, as-needed, and custom schedules are recorded without automatic reminders.',
                        ),
                      ),
                      TextEntry(controller: notes, label: 'Notes', lines: 2),
                    ],
                  ),
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
                    if (name.text.trim().isEmpty) {
                      setState(
                        () => error =
                            'Enter the medication name exactly as shown on the label.',
                      );
                    } else if (reminderMinutes >= 0 &&
                        !supportsDailyMedicationReminders(schedule.text)) {
                      setState(
                        () => error =
                            'Automatic reminders support daily schedules only. Select No reminder for this schedule.',
                      );
                    } else if (reminderMinutes >= 0 && times.isEmpty) {
                      setState(
                        () => error =
                            'Add a time for the daily reminder, or select No reminder.',
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
            await confirmEntryDeletion(context, 'medication')) {
          await state.deleteMedication(existing.id);
        }
      } else if (action == EntryDialogAction.save &&
          name.text.trim().isNotEmpty) {
        times.sort(
          (a, b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute),
        );
        await state.addMedication(
          Medication(
            id: existing?.id ?? newId(),
            name: name.text.trim(),
            strength: strength.text.trim(),
            dose: dose.text.trim(),
            schedule: schedule.text.trim(),
            notes: notes.text.trim(),
            active: existing?.active ?? true,
            times: times.map(timeToStorage).toSet().toList(),
            reminderMinutes: reminderMinutes,
          ),
        );
      }
    } finally {
      name.dispose();
      strength.dispose();
      dose.dispose();
      schedule.dispose();
      notes.dispose();
    }
  }

  Future<TimeOfDay?> _pickTimeDropdown(
    BuildContext context,
    TimeOfDay initial,
  ) {
    var picked = initial;
    return showDialog<TimeOfDay>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Choose time'),
          content: TimeDropdownEntry(
            value: picked,
            onChanged: (value) => setState(() => picked = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, picked),
              child: const Text('Use time'),
            ),
          ],
        ),
      ),
    );
  }
}
