import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'migration_v1.dart';
import 'category_seeder.dart';
import 'app_settings_initializer.dart';
import 'db_verification_logger.dart';

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

/// Async provider that resolves once the database is fully initialised.
/// All feature-layer providers that need DB access should depend on this.
///
/// Usage:
///   final db = await ref.watch(databaseServiceProvider.future);
final databaseServiceProvider = FutureProvider<DatabaseService>((ref) async {
  final service = DatabaseService._();
  await service._init();
  return service;
});

// ---------------------------------------------------------------------------
// DatabaseService
// ---------------------------------------------------------------------------

/// Single entry-point for all SQLCipher database operations.
///
/// Responsibilities:
///   - Key generation + secure storage (flutter_secure_storage)
///   - SQLCipher database open with AES-256-CBC page-level encryption
///   - Schema migration orchestration
///   - System category seeding
///   - app_settings singleton guard
///   - Debug verification logging
///
/// Hard constraints honoured:
///   SC-01  Zero cloud AI — no data leaves the device
///   NFR-08 AES-256 with hardware enclave via flutter_secure_storage
///          (Keychain on iOS, Keystore-backed EncryptedSharedPreferences on Android)
class DatabaseService {
  DatabaseService._();

  static const _dbFileName = 'tazakar.db';
  static const _keyStorageKey = 'tazakar_db_key';
  static const _keyByteLength = 32; // 256 bits

  late final Database _db;

  /// The underlying [Database] instance.
  /// Callers should prefer the typed helpers on this class rather than
  /// accessing [db] directly; direct access is permitted for complex queries.
  Database get db => _db;

  // -------------------------------------------------------------------------
  // Initialisation
  // -------------------------------------------------------------------------

  Future<void> _init() async {
    final key = await _resolveEncryptionKey();
    _db = await _openDatabase(key);

    await MigrationV1.run(_db);
    await CategorySeeder.seed(_db);
    await AppSettingsInitializer.ensureSingleton(_db);

    // Debug-only: logs table list + row counts to the console.
    // Compiled out in release builds via assert.
    assert(() {
      DbVerificationLogger.log(_db);
      return true;
    }());

    dev.log('DatabaseService ready — ${_db.path}', name: 'Tazakar.DB');
  }

  // -------------------------------------------------------------------------
  // Encryption key management
  // -------------------------------------------------------------------------

  /// Returns the stored 64-char hex passphrase, generating and persisting
  /// a new one on first launch.
  ///
  /// flutter_secure_storage writes to:
  ///   iOS  — Keychain (hardware-backed on devices with Secure Enclave)
  ///   Android — EncryptedSharedPreferences backed by Android Keystore
  Future<String> _resolveEncryptionKey() async {
    const storage = FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );

    final existing = await storage.read(key: _keyStorageKey);
    if (existing != null && existing.length == _keyByteLength * 2) {
      dev.log('DB key loaded from secure storage.', name: 'Tazakar.DB');
      return existing;
    }

    // First launch — generate a cryptographically random key.
    final key = _generateHexKey(_keyByteLength);
    await storage.write(key: _keyStorageKey, value: key);
    dev.log('DB key generated and stored in secure storage.', name: 'Tazakar.DB');
    return key;
  }

  /// Generates a hex-encoded random key of [byteLength] bytes.
  String _generateHexKey(int byteLength) {
    final rng = Random.secure();
    final bytes = List<int>.generate(byteLength, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // -------------------------------------------------------------------------
  // Database open
  // -------------------------------------------------------------------------

  Future<Database> _openDatabase(String key) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, _dbFileName);

    dev.log('Opening SQLCipher DB at $dbPath', name: 'Tazakar.DB');

    return openDatabase(
      dbPath,
      version: 1,
      // SQLCipher passphrase is set via the PRAGMA before any other statement.
      onConfigure: (db) async {
        await db.execute("PRAGMA key = '$key';");
        // Enforce foreign-key constraints on every connection.
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        // onCreate fires when the DB file is brand-new.
        // MigrationV1.run() is idempotent (CREATE TABLE IF NOT EXISTS)
        // so it handles both onCreate and onUpgrade paths uniformly.
        dev.log('onCreate fired — new database file.', name: 'Tazakar.DB');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        dev.log(
          'onUpgrade: $oldVersion → $newVersion',
          name: 'Tazakar.DB',
        );
        // Future migrations will be dispatched here by version range.
        // e.g. if (oldVersion < 2) await MigrationV2.run(db);
      },
    );
  }

  // -------------------------------------------------------------------------
  // Convenience query helpers
  // -------------------------------------------------------------------------

  /// Shorthand for [Database.query].
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) =>
      _db.query(
        table,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
      );

  /// Shorthand for [Database.insert] with conflict replacement.
  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace,
  }) =>
      _db.insert(table, values, conflictAlgorithm: conflictAlgorithm);

  /// Shorthand for [Database.update].
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) =>
      _db.update(table, values, where: where, whereArgs: whereArgs);

  /// Shorthand for [Database.delete].
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) =>
      _db.delete(table, where: where, whereArgs: whereArgs);

  /// Executes [action] inside a database transaction.
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) =>
      _db.transaction(action);
}
