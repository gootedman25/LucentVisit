import 'dart:typed_data';

import '../lucentvisit_repository.dart';
import 'backup_codec.dart';
import 'backup_models.dart';
import 'backup_repository.dart';

class BackupService {
  BackupService(this.repository, {BackupCodec? codec})
    : codec = codec ?? BackupCodec();

  final LucentVisitRepository repository;
  final BackupCodec codec;

  Future<Uint8List> createBackup(String password) async {
    final snapshot = BackupSnapshot(
      appointments: await repository.appointments(),
      medications: await repository.medications(),
      healthLog: await repository.healthLog(),
      measurements: await repository.measurements(),
    );
    return codec.encode(payload: snapshot.toJson(), password: password);
  }

  Future<PreparedBackupRestore> prepareRestore(
    Uint8List bytes,
    String password,
  ) async {
    final decoded = await codec.decode(bytes: bytes, password: password);
    try {
      final snapshot = BackupSnapshot.fromJson(decoded.payload);
      return PreparedBackupRestore(
        snapshot: snapshot,
        preview: BackupPreview(
          createdAt: decoded.createdAt,
          appointments: snapshot.appointments.length,
          medications: snapshot.medications.length,
          healthLogEntries: snapshot.healthLog.length,
          measurements: snapshot.measurements.length,
        ),
      );
    } on Object {
      throw const BackupCodecException('The backup contains invalid data.');
    }
  }

  Future<BackupRestoreResult> restorePrepared(PreparedBackupRestore prepared) {
    final atomicRepository = repository;
    if (atomicRepository is! AtomicBackupRepository) {
      throw StateError('Backup restore is not supported on this platform.');
    }
    return (atomicRepository as AtomicBackupRepository)
        .restoreMissingAtomically(prepared.snapshot);
  }
}
