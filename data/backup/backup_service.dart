import  'dart:typed_data';
import  '../lucentvisit_repository.dart';
import  'backup_code.dart';
import  'backup_snapshot.dart';
import  'backup_repository.dart';

class BackupService {
    BackupService({BackupCodec? codec,})  : _codec = codec ?? BackupCodec();

    static const int maxFileBytes = BackupCodec.maxFileBytes;
    final BackupCodec _codec;

    Future<Uint8List> createdBackup({
        required LucentVisitRepository repository,
        required String password,
    }) async {
        final snapshot = BackupSnapshot(
            appointments: await repository.appointments(),
            medications: await repository.medications(),
            healthLog: await repository.healthLog(),
            measurements: await repository.measurements(),
        );

        final validateSnapshot = BackupSnapshot.fromJson(snapshot.toJson());
        final payload = BackupPayload(
            createdAtUtc: DateTime.now().toUtc(),
            snapshot: validateSnapshot,
        );

        return _codec.encrypt(payload: payload.toJson(), password: password);
    }

    Future<PreparedBackupRestore> preparedRestore({
        required List<int> backupBytes,
        required String password,
        required LucentVisitRepository repository,
    }) async {
        final decrypted = await _codec.decrypt(backupBytes: backupBytes, password: password);
        final BackupPayload payload;

        try{
            payload = BackupPayload.fromJson(decrypted);
        } on FormatException {
            throw const BackupCodecException(type: BackupCodecExceptionType.invalidFormat, message: 'Failed to parse backup payload');
        }

        final currentAppointments = await repository.appointments();
        final currentMedications = await repository.medications();
        final currentHealthLog = await repository.healthLog();
        final currentMeasurements = await repository.measurements();

        final appointmentIds = currentAppointments.map((value) => value.id).toSet();
        final medicationIds = currentMedications.map((value) => value.id).toSet();
        final healthLogIds = currentHealthLog.map((value) => value.id).toSet();
        final measurementIds = currentMeasurements.map((value) => value.id).toSet();

        final snapshot = payload.snapshot;
        final preview = BackupPreview(
            createdAtUtc: payload.createdAtUtc,
            appointmentsInFile: snapshot.appointments.length,
            medicationsInFile: snapshot.medications.length,
            healthLogInFile: snapshot.healthLog.length,
            measurementsInFile: snapshot.measurements.length,
            appointmentsToAdd: snapshot.appointments.where((value) => !appointmentIds.contains(value.id)).length,
            medicationsToAdd: snapshot.medications.where((value) => !medicationIds.contains(value.id)).length,
            healthLogToAdd: snapshot.healthLog.where((value) => !healthLogIds.contains(value.id)).length,
            measurementsToAdd: snapshot.measurements.where((value) => !measurementIds.contains(value.id)).length,
        );

        return PreparedBackupRestore(
            snapshot: snapshot,
            preview: preview,
        );
    }

    Future<BackupRestoreResult> restorePrepared({
        required PreparedBackupRestore prepared,
        required LucentVisitRepository repository,
    }) async {
        if (repository is! AtomicBackupRepository) {
            throw StateError('Repository must be an instance of AtomicBackupRepository');
        }

        return repository.restoreMissingAtomically(
            prepared.snapshot,
        );
    }
}
