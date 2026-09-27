import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../app_state.dart';
import '../data/backup_service.dart';

class BackupCard extends StatefulWidget {
  const BackupCard({required this.state, super.key});
  final AppState state;

  @override
  State<BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends State<BackupCard> {
  bool _busy = false;
  final _service = BackupService();

  void _notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<String?> _password({required bool creating}) async {
    final password = TextEditingController();
    final confirmation = TextEditingController();
    String? error;
    final route = DialogRoute<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(creating ? 'Protect your backup' : 'Unlock backup'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  creating
                      ? 'Use a long, unique passphrase. Keep it somewhere safe: it cannot be recovered. Your file contains private health information. Choose a local folder if you do not want it in cloud storage.'
                      : 'Enter the passphrase used to create this backup.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: password,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(labelText: 'Passphrase'),
                ),
                if (creating) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmation,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Repeat passphrase',
                    ),
                  ),
                ],
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (password.text.isEmpty ||
                    (creating && password.text.length < 12)) {
                  update(
                    () => error = creating
                        ? 'Use at least 12 characters.'
                        : 'Enter your passphrase.',
                  );
                } else if (creating && password.text != confirmation.text) {
                  update(() => error = 'Passphrases do not match.');
                } else {
                  Navigator.pop(context, password.text);
                }
              },
              child: Text(creating ? 'Create backup' : 'Unlock'),
            ),
          ],
        ),
      ),
    );
    final result = await Navigator.of(context, rootNavigator: true).push(route);
    await route.completed;
    password.dispose();
    confirmation.dispose();
    return result;
  }

  Future<void> _run(bool restoring) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (restoring) {
        final file = await FilePicker.pickFile(
          dialogTitle: 'Choose LucentVisit backup',
        );
        if (file == null || !mounted) return;
        final size = await file.length();
        if (size == null || size > BackupService.maxFileBytes) {
          throw const FormatException('Choose a backup smaller than 20 MB.');
        }
        if (!mounted) return;
        final password = await _password(creating: false);
        if (password == null) return;
        final data = await _service.decrypt(await file.readAsBytes(), password);
        if (!mounted) return;
        final approved = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore backup?'),
            content: Text(
              '${data.summary}.\n\nOnly missing entries will be added. Existing entries will not be changed. Review appointment and medication reminders after restoring.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restore'),
              ),
            ],
          ),
        );
        if (approved != true) return;
        final added = await _service.restoreMissing(
          data,
          widget.state.repository,
        );
        await widget.state.load();
        _notice('Restore complete: $added entries added.');
      } else {
        final password = await _password(creating: true);
        if (password == null) return;
        final repository = widget.state.repository;
        final data = BackupData(
          appointments: await repository.appointments(),
          medications: await repository.medications(),
          healthLog: await repository.healthLog(),
          measurements: await repository.measurements(),
        );
        final bytes = await _service.encrypt(data, password);
        final saved = await FilePicker.saveFile(
          fileName:
              'lucentvisit-${DateTime.now().toIso8601String().substring(0, 10)}.lucentvisit',
          bytes: bytes,
          mimeType: 'application/octet-stream',
          dialogTitle: 'Save encrypted backup',
        );
        _notice(
          kIsWeb
              ? 'Backup download started. Check your Downloads folder and keep your passphrase safe.'
              : saved == null
              ? 'Backup save cancelled.'
              : 'Encrypted backup saved. Keep your passphrase safe.',
        );
      }
    } on FormatException catch (error) {
      _notice(error.message);
    } catch (_) {
      _notice(
        restoring
            ? 'Restore could not finish. Existing data is safe; retry to add any remaining entries.'
            : 'Backup could not be saved. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Encrypted backup',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Save a password-protected copy of all four entry types. Restore it on this device or another device. App preferences are not included.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy || widget.state.loading
                  ? null
                  : () => _run(false),
              icon: const Icon(Icons.save_alt),
              label: const Text('Save backup'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy || widget.state.loading
                  ? null
                  : () => _run(true),
              icon: const Icon(Icons.restore),
              label: const Text('Restore backup'),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    ),
  );
}
