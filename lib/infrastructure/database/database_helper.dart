import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tazakar/core/constants/app_constants.dart';
import 'package:tazakar/infrastructure/database/encryption_key_manager.dart';
import 'package:tazakar/core/database/migrations/migration_v2.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    final isFfi = databaseFactory.runtimeType.toString().contains('Ffi');

    if (isFfi) {
      // Test environment — plain sqflite_common_ffi, no encryption
      return databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: AppConstants.dbVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    // Device environment — SQLCipher via sqlcipher_flutter_libs
    final key = await EncryptionKeyManager.getOrCreateKey();
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async {
          await db.rawQuery("PRAGMA key = '$key'");
        },
      ),
    );
  }

  // ── Migration v1 Schema ─────────────────────────────────────────────
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        scheduled_at INTEGER NOT NULL,
        dialect_code TEXT NOT NULL DEFAULT "ar-AE",
        is_completed INTEGER NOT NULL DEFAULT 0,
        snoozed_until INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reminder_recurrences (
        id TEXT PRIMARY KEY,
        reminder_id TEXT NOT NULL,
        recurrence_type TEXT NOT NULL,
        interval_hours INTEGER,
        day_of_week INTEGER,
        ends_at INTEGER,
        FOREIGN KEY (reminder_id) REFERENCES reminders (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        is_system INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE notification_log (
        id TEXT PRIMARY KEY,
        reminder_id TEXT NOT NULL,
        fired_at INTEGER NOT NULL,
        action TEXT NOT NULL,
        FOREIGN KEY (reminder_id) REFERENCES reminders (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE promo_codes (
        code_hash TEXT PRIMARY KEY,
        redeemed_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Seed system categories
    await _seedCategories(db);

    // Seed default app settings
    await _seedAppSettings(db);

    debugPrint('[DB] Migration v1 complete — schema created and seeded.');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await MigrationV2.migrate(db);
    }
    debugPrint('[DB] Upgrade from v$oldVersion to v$newVersion');
  }

  // ── Seeds ────────────────────────────────────────────────────────────
  static Future<void> _seedCategories(Database db) async {
    final categories = [
      {'name_ar': 'عمل', 'name_en': 'Work', 'icon_code': 0xe8f9},
      {'name_ar': 'شخصي', 'name_en': 'Personal', 'icon_code': 0xe7fd},
      {'name_ar': 'صحة', 'name_en': 'Health', 'icon_code': 0xe87d},
      {'name_ar': 'عائلة', 'name_en': 'Family', 'icon_code': 0xe533},
      {'name_ar': 'مالية', 'name_en': 'Finance', 'icon_code': 0xe263},
      {'name_ar': 'تعليم', 'name_en': 'Education', 'icon_code': 0xe80c},
      {'name_ar': 'تسوق', 'name_en': 'Shopping', 'icon_code': 0xe8cc},
      {'name_ar': 'أخرى', 'name_en': 'Other', 'icon_code': 0xe8b8},
    ];

    for (final cat in categories) {
      await db.insert('categories', {...cat, 'is_system': 1});
    }
    debugPrint('[DB] Seeded ${categories.length} system categories.');
  }

  static Future<void> _seedAppSettings(Database db) async {
    final defaults = {
      'voice_gender': 'female',
      'theme_mode': 'system',
      'snooze_duration_minutes': '${AppConstants.defaultSnoozeDurationMinutes}',
      'subscription_status': 'free',
      'onboarding_complete': 'false',
      'app_language': 'ar',
    };

    for (final entry in defaults.entries) {
      await db.insert('app_settings', {
        'key': entry.key,
        'value': entry.value,
      });
    }
    debugPrint('[DB] Seeded ${defaults.length} default app settings.');
  }
}
