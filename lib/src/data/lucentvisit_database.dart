import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Owns the encrypted mobile database and its versioned schema.
class LucentVisitDatabase {
  LucentVisitDatabase._(this.db);

  @visibleForTesting
  LucentVisitDatabase.forTesting(this.db);

  final Database db;

  // These pre-LucentVisit identifiers are compatibility keys. Renaming them without
  // a migration would make existing installations appear to lose their data.
  static const _keyName = 'clearvisit.database.key.v1';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(migrateWithBackup: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );

  static Future<LucentVisitDatabase> open() async {
    final directory = await getApplicationSupportDirectory();
    final key = await _getOrCreateKey();
    final database = await openDatabase(
      p.join(directory.path, 'clearvisit.db'),
      password: key,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      // Migrations run in version order so an older installed app can upgrade
      // without deleting user data. Released migrations should remain fixed;
      // future schema changes get a new version and another guarded step.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE appointments ADD COLUMN reminder_minutes INTEGER NOT NULL DEFAULT -1',
          );
          await db.execute(
            "ALTER TABLE medications ADD COLUMN times TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            'ALTER TABLE medications ADD COLUMN reminder_minutes INTEGER NOT NULL DEFAULT -1',
          );
        }
        if (oldVersion < 3) {
          await _createSettingsTable(db);
        }
      },
      // A fresh install receives the complete current schema in one operation.
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE appointments (
            id TEXT PRIMARY KEY,
            date TEXT NOT NULL,
            reason TEXT NOT NULL,
            provider TEXT NOT NULL,
            documents TEXT NOT NULL,
            symptoms TEXT NOT NULL,
            questions TEXT NOT NULL,
            reminder_minutes INTEGER NOT NULL DEFAULT -1
          )
        ''');
        await db.execute('''
          CREATE TABLE medications (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            strength TEXT NOT NULL,
            dose TEXT NOT NULL,
            schedule TEXT NOT NULL,
            notes TEXT NOT NULL,
            active INTEGER NOT NULL CHECK(active IN (0, 1)),
            times TEXT NOT NULL DEFAULT '',
            reminder_minutes INTEGER NOT NULL DEFAULT -1
          )
        ''');
        await db.execute('''
          CREATE TABLE health_log_entries (
            id TEXT PRIMARY KEY,
            occurred_at TEXT NOT NULL,
            text TEXT NOT NULL,
            flagged INTEGER NOT NULL CHECK(flagged IN (0, 1))
          )
        ''');
        await db.execute('''
          CREATE TABLE measurements (
            id TEXT PRIMARY KEY,
            measured_at TEXT NOT NULL,
            type TEXT NOT NULL,
            value TEXT NOT NULL,
            unit TEXT NOT NULL,
            context TEXT NOT NULL
          )
        ''');
        await _createSettingsTable(db);
      },
    );
    return LucentVisitDatabase._(database);
  }

  static Future<void> _createSettingsTable(DatabaseExecutor db) =>
      db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');

  static Future<String> _getOrCreateKey() async {
    final existing = await _secureStorage.read(key: _keyName);
    if (existing != null) return existing;

    // Generate the database key once and keep it in platform secure storage,
    // separate from the encrypted database file. Random.secure delegates to the
    // operating system's cryptographically secure random-number source.
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final key = base64UrlEncode(bytes);
    await _secureStorage.write(key: _keyName, value: key);
    return key;
  }
}
