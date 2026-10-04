import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

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

    setState(() {
      _busy = true;
    });

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
    } catch (_) {
      _notice(
        restoring
            ? 'The backup could not be restored. No changes were made.'
            : 'The backup could not be saved. Please try again.',
      );
    } finally {
      if (mounted) {
        {
          setState(() {
          _busy = false;
        });
      }
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

  Future<void> _export() async {
    final password = await _password(creating: true);

    if (password == null || !mounted) return;

    final bytes = await _service.createBackup(
      repository: widget.state.repository,
      password: password,
    );

    final date = DateTime.now().toIso8601String().substring(0, 10);

    final saved = await FilePicker.saveFile(
      fileName: 'lucentvisit-$date.lucentvisit',
      bytes: bytes,
      mimeType: 'application/octet-stream',
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
    );

    if (file == null || !mounted) return;

    final size = await file.length();

    if (size == null ||
        size <= 0 ||
        size > BackupService.maxFileBytes) {
      throw BackupCodecException(
        type: BackupCodecErrorType.tooLarge,
        message:
            'Choose a valid backup smaller than '
            '${BackupService.maxFileBytes ~/ (1024 * 1024)} MB.',
      );
    }

    final password = await _password(creating: false);

    if (password == null || !mounted) return;

    final prepared = await _service.prepareRestore(
      backupBytes: await file.readAsBytes(),
      password: password,
      repository: widget.state.repository,
    );

    if (!mounted) return;

    final approved = await _confirmRestore(
      prepared.preview,
    );

    if (approved != true || !mounted) return;

    final result = await _service.restorePrepared(
      prepared: prepared,
      repository: widget.state.repository,
    );

    await widget.state.load();

    _notice(
      'Restore complete: ${result.added} added, '
      '${result.skipped} already present.',
    );
  }

  Future<bool?> _confirmRestore(
    BackupPreview preview,
  )  {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Review backup'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Created ${_formatBackupDate(preview.createdAtUtc)}',
                ),
                const SizedBox(height: 16),
                _PreviewRow(
                  label: 'Appointments',
                  inFile: preview.appointmentsInFile,
                  toAdd: preview.appointmentsToAdd,
                ),
                _PreviewRow(
                  label: 'Medications',
                  inFile: preview.medicationsInFile,
                  toAdd: preview.medicationsToAdd,
                ),
                _PreviewRow(
                  label: 'Health notes',
                  inFile: preview.healthNotesInFile,
                  toAdd: preview.healthNotesToAdd,
                ),
                _PreviewRow(
                  label: 'Measurements',
                  inFile: preview.measurementsInFile,
                  toAdd: preview.measurementsToAdd,
                ),
                const Divider(height: 28),
                Text(
                  '${preview.totalToAdd} entries will be added.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${preview.totalSkipped} entries already on this '
                  'device will be skipped.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Existing entries will not be changed. The restore '
                  'will be performed as one transaction. If anything '
                  'fails, no entries will be added.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Review appointment and medication reminders after '
                  'restoring.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: preview.totalToAdd == 0
                  ? null
                  : () {
                      Navigator.pop(context, true);
                    },
              child: Text(
                preview.totalToAdd == 0
                    ? 'Nothing to add'
                    : 'Restore ${preview.totalToAdd}',
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatBackupDate(DateTime utcValue) {
    final value = utcValue.toLocal();

    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hourOfPeriod == 0
        ? 12
        : value.hourOfPeriod;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour < 12 ? 'AM' : 'PM';

    return '$month/$day/${value.year} at '
        '$hour:$minute $period';
  }
}
