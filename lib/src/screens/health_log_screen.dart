import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import '../widgets/entry_fields.dart';

class HealthLogScreen extends StatelessWidget {
  const HealthLogScreen({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) => Column(
      children: [
        const ScreenIntro(
          title: 'Health log',
          body:
              'Write down what happened and flag anything you want to mention at your next visit.',
        ),
        Expanded(
          child: state.healthLog.isEmpty
              ? const EmptyState(
                  icon: Icons.edit_note,
                  title: 'Your log is empty',
                  body:
                      'Add a short note whenever something feels worth remembering.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
                  children: state.healthLog
                      .map(
                        (value) => SummaryCard(
                          icon: value.flagged
                              ? Icons.flag_outlined
                              : Icons.notes_outlined,
                          title: value.text,
                          subtitle:
                              '${weekdayName(value.occurredAt)}, ${shortDate(value.occurredAt)}${value.flagged ? ' • Raise at next visit' : ''}',
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
              label: const Text('Add log entry'),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _edit(BuildContext context, [HealthLogEntry? existing]) async {
    final text = TextEditingController(text: existing?.text);
    var occurredAt = existing?.occurredAt ?? DateTime.now();
    var flagged = existing?.flagged ?? false;
    String? error;
    try {
      final route = DialogRoute<EntryDialogAction>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: EntryDialogTitle(
              title: existing == null ? 'New log entry' : 'Edit log entry',
              error: error,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DateDropdownEntry(
                    value: occurredAt,
                    label: 'When did this happen?',
                    yearCount: 3,
                    onChanged: (value) =>
                        setDialogState(() => occurredAt = value),
                  ),
                  TextEntry(
                    controller: text,
                    label: 'What do you want to remember?',
                    lines: 4,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: flagged,
                    onChanged: (value) =>
                        setDialogState(() => flagged = value ?? false),
                    title: const Text('Raise at my next visit'),
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
                  if (text.text.trim().isEmpty) {
                    setDialogState(() => error = 'Write a note before saving.');
                  } else if (occurredAt.isAfter(DateTime.now())) {
                    setDialogState(
                      () => error =
                          'Choose the date this happened, not a future date.',
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
            await confirmEntryDeletion(context, 'health log entry')) {
          await state.deleteLog(existing.id);
        }
      } else if (action == EntryDialogAction.save &&
          text.text.trim().isNotEmpty) {
        await state.addLog(
          HealthLogEntry(
            id: existing?.id ?? newId(),
            occurredAt: occurredAt,
            text: text.text.trim(),
            flagged: flagged,
          ),
        );
      }
    } finally {
      text.dispose();
    }
  }
}
