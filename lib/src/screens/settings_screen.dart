import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../app_state.dart';
import '../widgets/common.dart';
import '../widgets/backup_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) => ListView(
      padding: EdgeInsets.zero,
      children: [
        ScreenIntro(
          title: 'Privacy and settings',
          body: kIsWeb
              ? 'Your entries stay in this browser. Save a backup before clearing browser data.'
              : 'Your entries stay in an encrypted database on this device.',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            children: [
              _ThemeModeCard(
                value: state.themeMode,
                onChanged: state.setThemeMode,
              ),
              BackupCard(state: state),
              const Padding(
                padding: EdgeInsets.only(bottom: 18),
                child: Text(
                  'Notes\nNo cloud sync: LuscentVist does not automatically upload your entries.\n\nPersonal organizer only: LuscentVist does not provide medical advice, diagnosis, monitoring, or treatment.',
                ),
              ),
              SummaryCard(
                icon: Icons.delete_forever,
                title: 'Delete everything',
                subtitle:
                    'Permanently removes all LuscentVist records from this device.',
                trailing: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.error,
                ),
                onTap: () => _confirmDelete(context),
              ),
              const SizedBox(height: 8),
              Text(
                'If you may be having a medical emergency, contact local emergency services. Do not rely on LuscentVist.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
          'This cannot be undone unless you previously created a backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed == true) await state.deleteEverything();
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colors.primaryContainer,
                child: Icon(Icons.contrast, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The app now follows the blue logo palette. Use dark mode when it is easier on your eyes.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ThemeMode>(
                      key: ValueKey(value),
                      initialValue: value,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Theme'),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('Use device setting'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                      ],
                      onChanged: (selected) {
                        if (selected != null) {
                          onChanged(selected);
                        }
                      },
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
