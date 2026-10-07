import 'package:flutter/material.dart';

import '../ai/ai_assistant_service.dart';
import '../ai/ai_models.dart';
import '../ai/ai_service_exception.dart';
import '../ai/app_check_token_provider.dart';
import '../app_state.dart';
import '../models/entry_validation.dart';
import '../models/models.dart';

enum _AiTask { explain, createDrafts }

class AiScreen extends StatefulWidget {
  const AiScreen({required this.state, super.key, this.service});
  final AppState state;
  final AiAssistantService? service;

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  late final AiAssistantService _service;
  final _text = TextEditingController();
  _AiTask _task = _AiTask.explain;
  bool _consent = false;
  bool _loading = false;

  void _changeTask(_AiTask? value) {
    if (value == null || value == _task) return;
    setState(() {
      _task = value;
      _text.clear();
      _consent = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _service =
        widget.service ??
        AiAssistantService(appCheckTokenProvider: getAppCheckToken);
  }

  @override
  void dispose() {
    _text.dispose();
    _service.close();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      if (_task == _AiTask.explain) {
        final result = await _service.explain(_text.text);
        if (mounted) await _showExplanation(result);
      } else {
        final result = await _service.createDrafts(_text.text);
        if (mounted) await _showDrafts(result);
      }
    } on AiServiceException catch (error) {
      if (mounted) _notice(error.message);
    } on FormatException {
      if (mounted) _notice('The AI service returned an invalid response.');
    } on Object {
      if (mounted) _notice('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _notice(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showExplanation(AiExplanation value) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.auto_awesome),
      title: const Text('Plain-language explanation'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResultSection(title: 'Summary', values: [value.summary]),
              _ResultSection(
                title: 'Important details',
                values: value.importantDetails,
              ),
              if (value.plainTerms.isNotEmpty)
                _ResultSection(
                  title: 'Plain terms',
                  values: value.plainTerms
                      .map((term) => '${term.term}: ${term.meaning}')
                      .toList(),
                ),
              _ResultSection(
                title: 'Questions to ask',
                values: value.questionsToAsk,
              ),
              _ResultSection(
                title: 'Uncertainties',
                values: value.uncertainties,
              ),
              _ResultSection(title: 'Cautions', values: value.cautions),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
  );

  Future<void> _showDrafts(List<AiDraft> drafts) async {
    final saved = <int>{};
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: const Icon(Icons.fact_check_outlined),
          title: const Text('Review organizer drafts'),
          content: SizedBox(
            width: 560,
            child: drafts.isEmpty
                ? const Text('No organizer entries were found in that text.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: drafts.length,
                    separatorBuilder: (_, _) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final draft = drafts[index];
                      final destination = _destinationFor(draft.type);
                      final alreadySaved = saved.contains(index);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _draftTitle(draft.type),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          for (final value in draft.values)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text('${value.field}: ${value.value}'),
                            ),
                          if (draft.missingRequired.isNotEmpty)
                            Text(
                              'Still needed: ${draft.missingRequired.join(', ')}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            'Source: ${draft.evidence}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          if (destination == null)
                            const Text(
                              'This item must be added to an existing visit manually.',
                            )
                          else if (alreadySaved)
                            const Row(
                              children: [
                                Icon(Icons.check_circle, size: 22),
                                SizedBox(width: 8),
                                Text('Saved'),
                              ],
                            )
                          else
                            FilledButton.tonalIcon(
                              onPressed: draft.missingRequired.isNotEmpty
                                  ? null
                                  : () async {
                                      final message = await _saveDraft(draft);
                                      if (!mounted || !dialogContext.mounted) {
                                        return;
                                      }
                                      if (message != null) {
                                        ScaffoldMessenger.of(
                                          this.context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(message)),
                                        );
                                        return;
                                      }
                                      setDialogState(() => saved.add(index));
                                      ScaffoldMessenger.of(
                                        this.context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Saved to $destination.',
                                          ),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.add_circle_outline),
                              label: Text('Save to $destination'),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _saveDraft(AiDraft draft) async {
    try {
      final values = {
        for (final value in draft.values)
          value.field.trim().toLowerCase().replaceAll(' ', '_'): value.value
              .trim(),
      };
      switch (draft.type) {
        case AiDraftType.appointment:
          final when = _dateTime(values);
          final reason = _required(values, 'reason');
          final reminderMinutes = _integer(values, 'reminder_minutes') ?? -1;
          if (reminderMinutes >= 0 &&
              !when
                  .subtract(Duration(minutes: reminderMinutes))
                  .isAfter(DateTime.now())) {
            return 'The proposed appointment reminder time has already passed.';
          }
          await widget.state.addAppointment(
            Appointment(
              id: newId(),
              date: when,
              reason: reason,
              provider: values['provider'] ?? '',
              documents: values['documents'] ?? '',
              symptoms: values['symptoms'] ?? '',
              questions: values['questions'] ?? '',
              reminderMinutes: reminderMinutes,
            ),
          );
        case AiDraftType.medication:
          final times = (values['times'] ?? '')
              .split(RegExp(r'[,;]'))
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList();
          final reminderMinutes = _integer(values, 'reminder_minutes') ?? -1;
          if (reminderMinutes >= 0 && times.isEmpty) {
            return 'Add a medication time before enabling its reminder.';
          }
          await widget.state.addMedication(
            Medication(
              id: newId(),
              name: _required(values, 'name'),
              strength: values['strength'] ?? '',
              dose: values['dose'] ?? '',
              schedule: values['schedule'] ?? '',
              notes: values['notes'] ?? '',
              times: times,
              reminderMinutes: reminderMinutes,
            ),
          );
        case AiDraftType.healthLog:
          await widget.state.addLog(
            HealthLogEntry(
              id: newId(),
              occurredAt: _dateTime(values),
              text: _required(values, 'text'),
              flagged: _boolean(values['flagged']),
            ),
          );
        case AiDraftType.measurement:
          final type = _required(values, 'type');
          final value = _required(values, 'value');
          final unit = _required(values, 'unit');
          final parts = value.split('/');
          final validation = measurementEntryError(
            type: type,
            value: value,
            unit: unit,
            systolic: parts.isNotEmpty ? parts.first : '',
            diastolic: parts.length == 2 ? parts.last : '',
          );
          if (validation != null) return validation;
          final measuredAt = _dateTime(values);
          if (measuredAt.isAfter(DateTime.now())) {
            return 'A measurement cannot be saved with a future date.';
          }
          await widget.state.addMeasurement(
            Measurement(
              id: newId(),
              measuredAt: measuredAt,
              type: type,
              value: value,
              unit: unit,
              context: values['context'] ?? '',
            ),
          );
        case AiDraftType.question:
        case AiDraftType.reminder:
        case AiDraftType.unknown:
          return 'This draft cannot be saved automatically.';
      }
      return null;
    } on FormatException catch (error) {
      return error.message;
    } on Object {
      return 'The draft could not be saved. Review its values and try again.';
    }
  }

  String _required(Map<String, String> values, String key) {
    final value = values[key];
    if (value == null || value.isEmpty) {
      throw FormatException('The draft still needs: $key.');
    }
    return value;
  }

  DateTime _dateTime(Map<String, String> values) {
    final date = _required(values, 'date');
    final time = _required(values, 'time');
    final parsed = DateTime.tryParse('${date}T$time');
    if (parsed == null) {
      throw const FormatException('The draft has an invalid date or time.');
    }
    return parsed;
  }

  int? _integer(Map<String, String> values, String key) {
    final value = values[key];
    if (value == null || value.isEmpty) return null;
    final parsed = int.tryParse(value);
    if (parsed == null) throw FormatException('$key must be a whole number.');
    return parsed;
  }

  bool _boolean(String? value) =>
      value?.toLowerCase() == 'true' || value == '1';

  String? _destinationFor(AiDraftType type) => switch (type) {
    AiDraftType.appointment => 'Visits',
    AiDraftType.medication => 'Meds',
    AiDraftType.healthLog => 'Notes',
    AiDraftType.measurement => 'Vitals',
    AiDraftType.question || AiDraftType.reminder || AiDraftType.unknown => null,
  };

  String _draftTitle(AiDraftType type) => switch (type) {
    AiDraftType.appointment => 'Appointment',
    AiDraftType.medication => 'Medication',
    AiDraftType.healthLog => 'Health note',
    AiDraftType.measurement => 'Measurement',
    AiDraftType.question => 'Question',
    AiDraftType.reminder => 'Reminder',
    AiDraftType.unknown => 'Unrecognized draft',
  };

  @override
  Widget build(BuildContext context) => SelectionArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI text helper',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explain confusing document text or extract organizer drafts. '
                  'This feature does not provide medical advice.',
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<_AiTask>(
                  initialValue: _task,
                  decoration: const InputDecoration(
                    labelText: 'Choose an action',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: _AiTask.explain,
                      child: Text('Explain text'),
                    ),
                    DropdownMenuItem(
                      value: _AiTask.createDrafts,
                      child: Text('Create organizer drafts'),
                    ),
                  ],
                  onChanged: _loading ? null : _changeTask,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _text,
                  minLines: 6,
                  maxLines: 12,
                  maxLength: AiAssistantService.maximumInputLength,
                  decoration: const InputDecoration(
                    labelText: 'Paste document text',
                    alignLabelWithHint: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _consent,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I choose to send this text for AI processing.',
                  ),
                  subtitle: const Text(
                    'The pasted text leaves this device and is processed by '
                    'LucentVisit’s cloud service and Anthropic.',
                  ),
                  onChanged: _loading
                      ? null
                      : (value) => setState(() => _consent = value ?? false),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed:
                        !_loading && _consent && _text.text.trim().isNotEmpty
                        ? _submit
                        : null,
                    icon: _loading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_loading ? 'Working…' : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.title, required this.values});
  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 5),
        if (values.isEmpty) const Text('None listed.'),
        for (final value in values) Text('• $value'),
      ],
    ),
  );
}
