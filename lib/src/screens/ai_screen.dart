import 'package:flutter/material.dart';

import '../ai/ai_assistant_service.dart';
import '../ai/ai_models.dart';
import '../ai/ai_service_exception.dart';

enum _AiTask { explain, createDrafts }

class AiScreen extends StatefulWidget {
  const AiScreen({super.key, this.service});
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

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AiAssistantService();
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

  Future<void> _showDrafts(List<AiDraft> drafts) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.type.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      for (final value in draft.values)
                        Text('${value.field}: ${value.value}'),
                      if (draft.missingRequired.isNotEmpty)
                        Text(
                          'Still needed: ${draft.missingRequired.join(', ')}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text('Source: ${draft.evidence}'),
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
  );

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
                  onChanged: _loading
                      ? null
                      : (value) => setState(() => _task = value ?? _task),
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
