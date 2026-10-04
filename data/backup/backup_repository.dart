import 'backup_models.dart';

abstract interface class AtomicBackupRepository {
  Future<BackupRestoreResult> restoreMissingAtomically(
    BackupSnapshot snapshot,
  );
}