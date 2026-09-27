import 'dart:convert';
import 'dart:typed_data';

import 'package:lucentvisit/src/data/backup_service.dart';
import 'package:lucentvisit/src/data/lucentvisit_repository.dart';
import 'package:lucentvisit/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = BackupService();
  const password = 'a unique backup passphrase';
  late Uint8List encrypted;
  final data = BackupData(
    appointments: [
      Appointment(id: 'a', date: DateTime(2026, 9, 1), reason: 'Checkup'),
    ],
    medications: const [
      Medication(id: 'm', name: 'Private medicine', times: ['09:37']),
    ],
    healthLog: [
      HealthLogEntry(
        id: 'h',
        occurredAt: DateTime(2026, 9, 1),
        text: 'Private note',
      ),
    ],
    measurements: [
      Measurement(
        id: 'v',
        measuredAt: DateTime(2026, 9, 1),
        type: 'Blood pressure',
        value: '120/80',
        unit: 'mmHg',
      ),
    ],
  );
  setUpAll(() async => encrypted = await service.encrypt(data, password));

  test('backup encrypts and round trips all four entry types', () async {
    expect(utf8.decode(encrypted), isNot(contains('Private note')));
    final envelope = jsonDecode(utf8.decode(encrypted)) as Map<String, dynamic>;
    expect(envelope['format'], 'lucentvisit-backup');
    final restored = await service.decrypt(encrypted, password);
    expect(restored.toMap(), data.toMap());
    expect(restored.measurements.single.systolic, 120);
    expect(restored.measurements.single.diastolic, 80);
  });
  test('wrong passphrase cannot decrypt', () async {
    await expectLater(
      service.decrypt(encrypted, 'wrong passphrase'),
      throwsFormatException,
    );
  });

  test('legacy ClearCue backup envelopes remain restorable', () async {
    final envelope = jsonDecode(utf8.decode(encrypted)) as Map<String, dynamic>;
    envelope['format'] = 'clearcue-backup';
    final legacy = Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
    final restored = await service.decrypt(legacy, password);
    expect(restored.toMap(), data.toMap());
  });

  test('previous-brand backup envelopes remain restorable', () async {
    final envelope = jsonDecode(utf8.decode(encrypted)) as Map<String, dynamic>;
    envelope['format'] = 'carecue-backup';
    final legacy = Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
    final restored = await service.decrypt(legacy, password);
    expect(restored.toMap(), data.toMap());
  });
  test('tampered ciphertext cannot decrypt', () async {
    final envelope = jsonDecode(utf8.decode(encrypted)) as Map<String, dynamic>;
    final ciphertext = base64Decode(envelope['ciphertext'] as String);
    ciphertext[0] ^= 1;
    envelope['ciphertext'] = base64Encode(ciphertext);
    await expectLater(
      service.decrypt(
        Uint8List.fromList(utf8.encode(jsonEncode(envelope))),
        password,
      ),
      throwsFormatException,
    );
  });
  test('backup rejects short passphrases', () async {
    await expectLater(service.encrypt(data, 'short'), throwsFormatException);
  });
  test('duplicate record IDs are rejected before restore', () {
    final map = data.toMap();
    map['medications'] = [
      data.medications.single.toMap(),
      data.medications.single.toMap(),
    ];
    expect(() => BackupData.fromMap(map), throwsFormatException);
  });

  test('restore preserves newer records and is safe to repeat', () async {
    final repository = _RestoreRepository();
    repository.meds.add(const Medication(id: 'm', name: 'Newer label'));
    expect(await service.restoreMissing(data, repository), 3);
    expect(repository.meds.single.name, 'Newer label');
    expect(await service.restoreMissing(data, repository), 0);
    expect(repository.visits.length, 1);
  });
}

class _RestoreRepository implements LucentVisitRepository {
  final visits = <Appointment>[];
  final meds = <Medication>[];
  final notes = <HealthLogEntry>[];
  final vitals = <Measurement>[];
  @override
  Future<List<Appointment>> appointments() async => visits;
  @override
  Future<List<Medication>> medications() async => meds;
  @override
  Future<List<HealthLogEntry>> healthLog() async => notes;
  @override
  Future<List<Measurement>> measurements() async => vitals;
  @override
  Future<void> saveAppointment(Appointment value) async => visits.add(value);
  @override
  Future<void> saveMedication(Medication value) async => meds.add(value);
  @override
  Future<void> saveHealthLogEntry(HealthLogEntry value) async =>
      notes.add(value);
  @override
  Future<void> saveMeasurement(Measurement value) async => vitals.add(value);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
