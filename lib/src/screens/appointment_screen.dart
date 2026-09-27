import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import '../widgets/entry_fields.dart';

const List<String> _reasonOptions = [
  'Annual physical',
  'Follow-up visit',
  'New symptom or concern',
  'Medication review or refill',
  'Lab work or test results',
  'Vaccination',
  'Specialist referral',
  'Urgent concern',
];

const List<String> _providerTypes = [
  'Primary care',
  'Cardiology',
  'Dermatology',
  'Endocrinology',
  'Gastroenterology',
  'Neurology',
  'OB-GYN',
  'Oncology',
  'Ophthalmology',
  'Orthopedics',
  'Psychiatry',
  'Urgent care',
  'Dentist',
];

class AppointmentScreen extends StatelessWidget {
  const AppointmentScreen({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => Column(
        children: [
          const ScreenIntro(
            title: 'Prepare for a visit',
            body:
                'Keep the important details together so they are easier to remember in the room.',
          ),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.appointments.isEmpty
                ? const EmptyState(
                    icon: Icons.event_available,
                    title: 'No visits yet',
                    body:
                        'Add an upcoming appointment and the questions you want to ask.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
                    itemCount: state.appointments.length,
                    itemBuilder: (context, index) {
                      final value = state.appointments[index];
                      return SummaryCard(
                        icon: Icons.event_note_outlined,
                        title: value.reason,
                        subtitle:
                            '${weekdayName(value.date)}, ${shortDate(value.date)} at ${formatTimeOfDay(TimeOfDay.fromDateTime(value.date))}${value.provider.isEmpty ? '' : ' • ${value.provider}'}',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showSummary(context, value),
                      );
                    },
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
                label: const Text('Add appointment'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const Map<int, String> _reminderChoices = {
    -1: 'No reminder',
    0: 'At time of appointment',
    5: '5 minutes before',
    10: '10 minutes before',
    15: '15 minutes before',
    30: '30 minutes before',
    60: '1 hour before',
    120: '2 hours before',
    1440: '1 day before',
  };

  Future<void> _edit(BuildContext context, [Appointment? existing]) async {
    final reason = TextEditingController(text: existing?.reason);
    final provider = TextEditingController(text: existing?.provider);
    final documents = TextEditingController(text: existing?.documents);
    final symptoms = TextEditingController(text: existing?.symptoms);
    final questions = TextEditingController(text: existing?.questions);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    var when =
        existing?.date ??
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
    var reminderMinutes = existing?.reminderMinutes ?? -1;
    String? error;
    final usedProviders = state.appointments
        .map((value) => value.provider.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    final providerOptions = [
      ...usedProviders,
      ..._providerTypes.where((type) => !usedProviders.contains(type)),
    ];
    try {
      final route = DialogRoute<EntryDialogAction>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: EntryDialogTitle(
              title: existing == null ? 'New appointment' : 'Edit appointment',
              error: error,
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    DateDropdownEntry(
                      value: when,
                      label: 'Appointment date',
                      firstYearOffset: 0,
                      yearCount: 4,
                      onChanged: (picked) => setState(() => when = picked),
                    ),
                    TimeDropdownEntry(
                      value: TimeOfDay.fromDateTime(when),
                      label: 'Appointment time',
                      onChanged: (picked) => setState(
                        () => when = DateTime(
                          when.year,
                          when.month,
                          when.day,
                          picked.hour,
                          picked.minute,
                        ),
                      ),
                    ),
                    DropdownEntry(
                      controller: reason,
                      label: 'Reason for visit',
                      options: _reasonOptions,
                    ),
                    DropdownEntry(
                      controller: provider,
                      label: 'Provider or clinic',
                      options: providerOptions,
                    ),
                    ReminderDropdown(
                      value: reminderMinutes,
                      choices: _reminderChoices,
                      onChanged: (value) =>
                          setState(() => reminderMinutes = value),
                    ),
                    TextEntry(
                      controller: documents,
                      label: 'Documents to bring',
                      lines: 2,
                    ),
                    TextEntry(
                      controller: symptoms,
                      label: 'Symptoms or concerns',
                      lines: 3,
                    ),
                    TextEntry(
                      controller: questions,
                      label: 'Questions to ask',
                      lines: 3,
                    ),
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
                  if (reason.text.trim().isEmpty) {
                    setState(
                      () => error = 'Choose or enter a reason for this visit.',
                    );
                  } else if (reminderMinutes >= 0 &&
                      !when
                          .subtract(Duration(minutes: reminderMinutes))
                          .isAfter(DateTime.now())) {
                    setState(
                      () => error =
                          'This reminder time has already passed. Choose a future reminder or No reminder.',
                    );
                  } else {
                    Navigator.pop(context, EntryDialogAction.save);
                  }
                },
                child: Text(existing == null ? 'Save' : 'Update'),
              ),
            ],
          ),
        ),
      );
      final action = await Navigator.of(
        context,
        rootNavigator: true,
      ).push(route);
      await route.completed;
      if (action == EntryDialogAction.delete && existing != null) {
        if (context.mounted &&
            await confirmEntryDeletion(context, 'appointment')) {
          await state.deleteAppointment(existing.id);
        }
      } else if (action == EntryDialogAction.save &&
          reason.text.trim().isNotEmpty) {
        await state.addAppointment(
          Appointment(
            id: existing?.id ?? newId(),
            date: when,
            reason: reason.text.trim(),
            provider: provider.text.trim(),
            documents: documents.text.trim(),
            symptoms: symptoms.text.trim(),
            questions: questions.text.trim(),
            reminderMinutes: reminderMinutes,
          ),
        );
      }
    } finally {
      reason.dispose();
      provider.dispose();
      documents.dispose();
      symptoms.dispose();
      questions.dispose();
    }
  }

  Future<void> _showSummary(BuildContext context, Appointment value) async {
    final edit = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            value.reason,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            '${weekdayName(value.date)}, ${shortDate(value.date)} at ${formatTimeOfDay(TimeOfDay.fromDateTime(value.date))}${value.provider.isEmpty ? '' : ' • ${value.provider}'}',
          ),
          const Divider(height: 32),
          _section('Bring', value.documents),
          _section('Mention', value.symptoms),
          _section('Ask', value.questions),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit appointment'),
          ),
        ],
      ),
    );
    if (edit == true && context.mounted) await _edit(context, value);
  }

  Widget _section(String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value.isEmpty ? 'Nothing added' : value),
      ],
    ),
  );
}
