import 'package:flutter/material.dart';

import '../ai/ai_assistant_service.dart';
import '../ai/ai_models.dart';
import '../ai/ai_service_exception.dart';

enum _AiTask {
  explain,
  createDrafts,
}

class AiScreen extends StatefulWidget {
  const AiScreen({
    super.key,
    this.service,
  });

  final AiAssistantService? service;

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  late final AiAssistantService _service;
  late final TextEditingController _textController;

  _AiTask _task = _AiTask.explain;
  bool _consentGiven = false;
  bool _isLoading = false;

  AiExplanation? _explanation;
  List<AiDraft>? _drafts;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AiAssistantService();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _service.close();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _explanation = null;
      _drafts = null;
    });

    try {
      switch (_task) {
        case _AiTask.explain:
          final result = await _service.explain(
            _textController.text,
          );

          if (!mounted) return;

          setState(() {
            _explanation = result;
          });

        case _AiTask.createDrafts:
          final result = await _service.createDrafts(
            _textController.text,
          );

          if (!mounted) return;

          setState(() {
            _drafts = result;
          });
      }
    } on AiServiceException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Something unexpected happened. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool get _canSubmit {
    return !_isLoading &&
        _consentGiven &&
        _textController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('AI text helper'),
      ),
      body: SafeArea(
        child: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Understand or organize text',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Paste text from a medical or insurance document. '
                'LucentVisit can explain it or prepare entries for you '
                'to review.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<_AiTask>(
                initialValue: _task,
                decoration: const InputDecoration(
                  labelText: 'What would you like to do?',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: _AiTask.explain,
                    child: Text('Explain the text'),
                  ),
                  DropdownMenuItem(
                    value: _AiTask.createDrafts,
                    child: Text('Create organizer drafts'),
                  ),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          _task = value;
                          _explanation = null;
                          _drafts = null;
                          _errorMessage = null;
                        });
                      },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                minLines: 7,
                maxLines: 14,
                maxLength: AiAssistantService.maximumInputLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Document text',
                  hintText: 'Paste or type the text here',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),
              Card(
                child: CheckboxListTile(
                  value: _consentGiven,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I understand that this text will leave my device.',
                  ),
                  subtitle: const Text(
                    'The text will be sent to LucentVisit’s cloud '
                    'service and Anthropic for processing. Do not '
                    'submit information unless you choose to share it.',
                  ),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _consentGiven = value ?? false;
                          });
                        },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _canSubmit ? _submit : null,
                  icon: _isLoading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isLoading
                        ? 'Working…'
                        : _task == _AiTask.explain
                        ? 'Explain text'
                        : 'Create drafts',
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                _ErrorCard(message: _errorMessage!),
              ],
              if (_explanation != null) ...[
                const SizedBox(height: 24),
                _ExplanationView(explanation: _explanation!),
              ],
              if (_drafts != null) ...[
                const SizedBox(height: 24),
                _DraftsView(drafts: _drafts!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: colors.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colors.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationView extends StatelessWidget {
  const _ExplanationView({
    required this.explanation,
  });

  final AiExplanation explanation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Explanation',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              explanation.summary,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        _StringSection(
          title: 'Important details',
          values: explanation.importantDetails,
        ),
        if (explanation.plainTerms.isNotEmpty)
          _PlainTermsSection(terms: explanation.plainTerms),
        _StringSection(
          title: 'Questions to ask',
          values: explanation.questionsToAsk,
        ),
        _StringSection(
          title: 'Uncertainties',
          values: explanation.uncertainties,
        ),
        _StringSection(
          title: 'Cautions',
          values: explanation.cautions,
        ),
      ],
    );
  }
}

class _PlainTermsSection extends StatelessWidget {
  const _PlainTermsSection({
    required this.terms,
  });

  final List<AiPlainTerm> terms;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plain-language terms',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final term in terms) ...[
              Text(
                term.term,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(term.meaning),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _StringSection extends StatelessWidget {
  const _StringSection({
    required this.title,
    required this.values,
  });

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            for (final value in values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(value)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DraftsView extends StatelessWidget {
  const _DraftsView({
    required this.drafts,
  });

  final List<AiDraft> drafts;

  @override
  Widget build(BuildContext context) {
    if (drafts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'No organizer entries were found in this text.',
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Drafts to review',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        const Text(
          'Nothing has been saved. Review every detail before adding it.',
        ),
        const SizedBox(height: 12),
        for (final draft in drafts)
          _DraftCard(draft: draft),
      ],
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
  });

  final AiDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _draftTypeLabel(draft.type),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final value in draft.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        _fieldLabel(value.field),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Text(value.value)),
                  ],
                ),
              ),
            if (draft.missingRequired.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Needs more information',
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                draft.missingRequired
                    .map(_fieldLabel)
                    .join(', '),
              ),
            ],
            const Divider(height: 28),
            Text(
              'Found in the document:',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              draft.evidence,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String _draftTypeLabel(AiDraftType type) {
  return switch (type) {
    AiDraftType.appointment => 'Appointment',
    AiDraftType.medication => 'Medication',
    AiDraftType.healthLog => 'Health log entry',
    AiDraftType.measurement => 'Measurement',
    AiDraftType.question => 'Question',
    AiDraftType.reminder => 'Reminder',
    AiDraftType.unknown => 'Unknown draft',
  };
}

String _fieldLabel(String value) {
  if (value.isEmpty) return value;

  final words = value
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .toList();

  if (words.isEmpty) return value;

  final label = words.join(' ');
  return '${label[0].toUpperCase()}${label.substring(1)}';
}
