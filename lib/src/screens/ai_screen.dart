import 'package:flutter/material.dart';

import '../ai/ai_assistant_service.dart';
import '../app_state.dart';
import '../widgets/common.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({required this.state, super.key});

  final AppState state;

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final AiAssistantService _assistant = const AiAssistantService();
  final TextEditingController _explainController = TextEditingController();
  final TextEditingController _draftController = TextEditingController();
  AiExplanation? _explanation;
  List<AiDraft> _drafts = const [];
  bool _explaining = false;
  bool _drafting = false;

  @override
  void dispose() {
    _explainController.dispose();
    _draftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          children: [
            const _CompactAiIntro(),
            const _SafetyNotice(),
            _ExplainCard(
              controller: _explainController,
              explanation: _explanation,
              loading: _explaining,
              onExplain: _explain,
            ),
            _DraftCard(
              controller: _draftController,
              drafts: _drafts,
              loading: _drafting,
              onDraft: _draftEntries,
              onSaveDraft: _saveDraft,
            ),
          ],
        ),
      ),
    ],
  );

  Future<void> _explain() async {
    if (_explainController.text.trim().isEmpty) return;
    setState(() => _explaining = true);
    try {
      final result = await _assistant.explain(_explainController.text);
      if (!mounted) return;
      setState(() => _explanation = result);
      await _showExplanationDialog(result);
    } catch (_) {
      if (!mounted) return;
      _showError('Could not explain that text. Please try again.');
    } finally {
      if (mounted) setState(() => _explaining = false);
    }
  }

  Future<void> _draftEntries() async {
    if (_draftController.text.trim().isEmpty) return;
    setState(() => _drafting = true);
    try {
      final result = await _assistant.createDrafts(_draftController.text);
      if (!mounted) return;
      setState(() => _drafts = result);
      await _showDraftsDialog(result);
    } catch (_) {
      if (!mounted) return;
      _showError('Could not create drafts from that text. Please try again.');
    } finally {
      if (mounted) setState(() => _drafting = false);
    }
  }

  Future<bool> _saveDraft(AiDraft draft) async {
    // This is the approval boundary: parsing creates only an in-memory draft;
    // choosing Save is what writes that specific draft through AppState.
    try {
      switch (draft.type) {
        case AiDraftType.appointment:
          final value = draft.appointment;
          if (value != null) await widget.state.addAppointment(value);
          break;
        case AiDraftType.medication:
          final value = draft.medication;
          if (value != null) await widget.state.addMedication(value);
          break;
        case AiDraftType.healthLog:
          final value = draft.healthLogEntry;
          if (value != null) await widget.state.addLog(value);
          break;
        case AiDraftType.measurement:
          final value = draft.measurement;
          if (value != null) await widget.state.addMeasurement(value);
          break;
      }
    } catch (_) {
      if (!mounted) return false;
      _showError('Could not save that draft. Please try again.');
      return false;
    }
    if (!mounted) return true;
    setState(() => _drafts = _drafts.where((item) => item != draft).toList());
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Added ${draft.title}')));
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showExplanationDialog(AiExplanation explanation) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.article_outlined),
        title: const Text('Text explanation ready'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ResultSection(
                title: 'Plain-language summary',
                values: [explanation.summary],
              ),
              _ResultSection(
                title: 'Important details',
                values: explanation.importantDetails,
              ),
              _ResultSection(
                title: 'Questions to ask',
                values: explanation.questionsToAsk,
              ),
              _ResultSection(
                title: 'Safety notes',
                values: explanation.cautions,
              ),
            ],
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
  }

  Future<void> _showDraftsDialog(List<AiDraft> drafts) {
    final visibleDrafts = [...drafts];
    return showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: const Icon(Icons.playlist_add_check_circle_outlined),
          title: const Text('Text drafts ready'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    visibleDrafts.isEmpty
                        ? 'All suggested entries have been added.'
                        : 'Review each suggestion before adding it to LucentVisit.',
                  ),
                  const SizedBox(height: 16),
                  for (final draft in visibleDrafts)
                    _DraftTile(
                      draft: draft,
                      onSave: () async {
                        final saved = await _saveDraft(draft);
                        if (context.mounted) {
                          if (saved) {
                            setDialogState(() => visibleDrafts.remove(draft));
                          }
                        }
                      },
                    ),
                ],
              ),
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
}

class _CompactAiIntro extends StatelessWidget {
  const _CompactAiIntro();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF54C5F8), Color(0xFF02569B)],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withAlpha(30),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.article_outlined, color: Colors.white, size: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Text helper prototype',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Organize pasted text or create reviewable LucentVisit drafts.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withAlpha(235),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colors.primaryContainer,
                child: Icon(
                  Icons.privacy_tip_outlined,
                  color: colors.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review before saving',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'The text helper creates drafts only. It does not diagnose, treat, or check medication safety.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplainCard extends StatelessWidget {
  const _ExplainCard({
    required this.controller,
    required this.explanation,
    required this.loading,
    required this.onExplain,
  });

  final TextEditingController controller;
  final AiExplanation? explanation;
  final bool loading;
  final VoidCallback onExplain;

  @override
  Widget build(BuildContext context) => _Panel(
    icon: Icons.article_outlined,
    title: 'Explain pasted text',
    subtitle: 'Letters, insurance notices, visit instructions, or bills.',
    actionLabel: explanation == null ? 'Open paste box' : 'Open or view result',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          minLines: 5,
          maxLines: 9,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Paste confusing text',
            hintText: 'Paste the paragraph or notice you want explained.',
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton.icon(
            onPressed: loading ? null : onExplain,
            icon: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(loading ? 'Explaining...' : 'Explain'),
          ),
        ),
        if (explanation != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              onPressed: loading
                  ? null
                  : () => _showExplanationFromCard(context, explanation!),
              icon: const Icon(Icons.open_in_new),
              label: const Text('View last explanation'),
            ),
          ),
      ],
    ),
  );

  Future<void> _showExplanationFromCard(
    BuildContext context,
    AiExplanation explanation,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.auto_awesome),
        title: const Text('Text explanation'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ResultSection(
                title: 'Plain-language summary',
                values: [explanation.summary],
              ),
              _ResultSection(
                title: 'Important details',
                values: explanation.importantDetails,
              ),
              _ResultSection(
                title: 'Questions to ask',
                values: explanation.questionsToAsk,
              ),
              _ResultSection(
                title: 'Safety notes',
                values: explanation.cautions,
              ),
            ],
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
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.controller,
    required this.drafts,
    required this.loading,
    required this.onDraft,
    required this.onSaveDraft,
  });

  final TextEditingController controller;
  final List<AiDraft> drafts;
  final bool loading;
  final VoidCallback onDraft;
  final Future<bool> Function(AiDraft draft) onSaveDraft;

  @override
  Widget build(BuildContext context) => _Panel(
    icon: Icons.playlist_add_check_circle_outlined,
    title: 'Create entries from text',
    subtitle: 'Turn notes into visits, meds, notes, or vitals.',
    actionLabel: drafts.isEmpty ? 'Open paste box' : 'Open or view drafts',
    child: Column(
      children: [
        TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Paste or type details',
            hintText:
                'Example: Follow-up visit 9/12 at 2 PM, remind me 1 day before.',
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton.icon(
            onPressed: loading ? null : onDraft,
            icon: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high),
            label: Text(loading ? 'Creating drafts...' : 'Create drafts'),
          ),
        ),
        if (drafts.isNotEmpty) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: loading
                ? null
                : () => _showDraftsFromCard(context, drafts, onSaveDraft),
            icon: const Icon(Icons.open_in_new),
            label: Text(
              'View ${drafts.length} draft${drafts.length == 1 ? '' : 's'}',
            ),
          ),
        ],
      ],
    ),
  );

  Future<void> _showDraftsFromCard(
    BuildContext context,
    List<AiDraft> drafts,
    Future<bool> Function(AiDraft draft) onSaveDraft,
  ) {
    final visibleDrafts = [...drafts];
    return showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: const Icon(Icons.playlist_add_check_circle_outlined),
          title: const Text('Text drafts'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    visibleDrafts.isEmpty
                        ? 'All suggested entries have been added.'
                        : 'Review each suggestion before adding it to LucentVisit.',
                  ),
                  const SizedBox(height: 16),
                  for (final draft in visibleDrafts)
                    _DraftTile(
                      draft: draft,
                      onSave: () async {
                        final saved = await onSaveDraft(draft);
                        if (context.mounted && saved) {
                          setDialogState(() => visibleDrafts.remove(draft));
                        }
                      },
                    ),
                ],
              ),
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
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          leading: CircleAvatar(
            radius: 21,
            backgroundColor: colors.primaryContainer,
            child: Icon(icon, color: colors.onPrimaryContainer, size: 25),
          ),
          title: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  actionLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          children: [child],
        ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.title, required this.values});

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        for (final value in values)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $value'),
          ),
      ],
    ),
  );
}

class _DraftTile extends StatelessWidget {
  const _DraftTile({required this.draft, required this.onSave});

  final AiDraft draft;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final icon = switch (draft.type) {
      AiDraftType.appointment => Icons.event_note_outlined,
      AiDraftType.medication => Icons.medication_outlined,
      AiDraftType.healthLog => Icons.notes_outlined,
      AiDraftType.measurement => Icons.monitor_heart_outlined,
    };
    final label = switch (draft.type) {
      AiDraftType.appointment => 'Visit',
      AiDraftType.medication => 'Medication',
      AiDraftType.healthLog => 'Log',
      AiDraftType.measurement => 'Measurement',
    };
    return SummaryCard(
      icon: icon,
      title: '$label: ${draft.title}',
      subtitle: '${draft.subtitle}\nWhy: ${draft.reason}',
      trailing: FilledButton(onPressed: onSave, child: const Text('Add')),
    );
  }
}
