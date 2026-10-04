import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/backup/backup_codec.dart';
import '../data/backup/backup_models.dart';
import '../data/backup/backup_service.dart';

class BackupCard extends StatefulWidget {
  const BackupCard({required this.state, super.key});
  final AppState state;

  @override
  State<BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends State<BackupCard> {
  bool _busy = false;

  BackupService get _service => BackupService(widget.state.repository);

  void _notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<String?> _password({required bool creating}) async {
    final password = TextEditingController();
    final confirmation = TextEditingController();
    String? error;
    final result = await showDialog<String>(
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
                      ? 'Use at least 12 characters. This password cannot be recovered.'
                      : 'Enter the password used to create this backup.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: password,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Backup password',
                  ),
                ),
                if (creating) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmation,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Repeat password',
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
                if (password.text.length < 12) {
                  update(() => error = 'Use at least 12 characters.');
                } else if (creating && password.text != confirmation.text) {
                  update(() => error = 'Passwords do not match.');
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
    password.dispose();
    confirmation.dispose();
    return result;
  }

  Future<void> _run(bool restoring) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (restoring) {
        await _restore();
      } else {
        await _export();
      }
    } on BackupCodecException catch (error) {
      _notice(error.message);
    } on StateError catch (error) {
      _notice(error.message);
    } on Object {
      _notice(
        restoring
            ? 'The backup could not be restored. No changes were made.'
            : 'The backup could not be saved. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    final password = await _password(creating: true);
    if (password == null || !mounted) return;
    final bytes = await _service.createBackup(password);
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final saved = await FilePicker.saveFile(
      fileName: 'lucentvisit-$date.lucentvisit',
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: const ['lucentvisit'],
      dialogTitle: 'Save encrypted backup',
    );
    _notice(
      kIsWeb
          ? 'Backup download started. Keep the file and password safe.'
          : saved == null
          ? 'Backup save cancelled.'
          : 'Encrypted backup saved. Keep the password safe.',
    );
  }

  Future<void> _restore() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Choose LucentVisit backup',
      type: FileType.custom,
      allowedExtensions: const ['lucentvisit'],
    );
    if (file == null || !mounted) return;
    final size = await file.length();
    if (size == null || size <= 0 || size > BackupCodec.maxBackupBytes) {
      throw const BackupCodecException(
        'Choose a valid backup smaller than 15 MB.',
      );
    }
    final bytes = await file.readAsBytes();
    final password = await _password(creating: false);
    if (password == null || !mounted) return;
    final prepared = await _service.prepareRestore(bytes, password);
    if (!mounted || await _confirmRestore(prepared.preview) != true) return;
    final result = await _service.restorePrepared(prepared);
    await widget.state.load();
    _notice('Restore complete: ${result.total} missing entries added.');
  }

  Future<bool?> _confirmRestore(BackupPreview preview) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Review backup'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Created ${preview.createdAt.toLocal()}'),
          const SizedBox(height: 12),
          _PreviewRow(label: 'Appointments', count: preview.appointments),
          _PreviewRow(label: 'Medications', count: preview.medications),
          _PreviewRow(label: 'Health notes', count: preview.healthLogEntries),
          _PreviewRow(label: 'Measurements', count: preview.measurements),
          const SizedBox(height: 12),
          const Text(
            'Only missing entries will be added. Existing entries are unchanged. '
            'If any insert fails, no entries are added.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Restore ${preview.total}'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Card(
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
            'Save a password-protected copy of your entries. The file is encrypted on this device.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy || widget.state.loading ? null : () => _run(false),
            icon: const Icon(Icons.save_alt),
            label: const Text('Save backup'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy || widget.state.loading ? null : () => _run(true),
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
  );
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text('$count')],
    ),
  );
}
