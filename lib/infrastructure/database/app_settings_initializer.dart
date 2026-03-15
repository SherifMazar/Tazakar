import 'dart:developer' as dev;

import 'package:sqflite/sqflite.dart';

// ---------------------------------------------------------------------------
// AppSettingsInitializer
// ---------------------------------------------------------------------------
//
// Guarantees that the app_settings table always contains exactly one row
// (id = 1) by the time DatabaseService.init() completes.
//
// Two-layer singleton defence (both must hold):
//
//   Layer 1 — SQLite engine:
//     The app_settings table has CHECK (id = 1) on its primary key column.
//     Any attempt to insert a row with id != 1 is rejected at the engine
//     level before Dart even sees it.
//
//   Layer 2 — Dart / application:
//     ensureSingleton() uses INSERT OR IGNORE so that:
//       • Cold start  → row does not exist → INSERT succeeds → 1 row.
//       • Warm start  → row already exists → IGNORE fires   → still 1 row.
//       • Re-install  → fresh DB, same as cold start.
//
// The singleton row is never updated by this class. All updates to
// app_settings go through AppSettingsRepository (Phase 4), which issues
// targeted UPDATE statements on specific columns.
//
// Default values (match migration_v1.dart column DEFAULTs):
//   dialect_pref          'auto'   — auto-detect from device locale
//   theme_pref            'dark'   — dark mode default (DEC-12)
//   onboarding_done        0       — onboarding not yet completed
//   pro_entitlement_cache  0       — free tier until store confirms pro
//   last_rc_fetch          NULL    — no Remote Config fetch yet
// ---------------------------------------------------------------------------

class AppSettingsInitializer {
  AppSettingsInitializer._();

  /// Ensures exactly one row exists in app_settings (id = 1).
  ///
  /// Must be called after [MigrationV1.run] has created the table.
  /// Safe to call on every app start — warm-start call is a no-op.
  static Future<void> ensureSingleton(Database db) async {
    dev.log('AppSettingsInitializer: ensuring singleton row…', name: 'Tazakar.DB');

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    await db.insert(
      'app_settings',
      {
        'id': 1,
        'dialect_pref': 'auto',
        'theme_pref': 'dark',
        'onboarding_done': 0,
        'pro_entitlement_cache': 0,
        'last_rc_fetch': null,
        'updated_at': nowMs,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    // Verify — read back the row and log its current state.
    // This runs in both debug and release builds intentionally:
    // a missing settings row would cause a hard crash in AppSettingsProvider
    // and we want Crashlytics to capture it if it ever happens.
    final rows = await db.query(
      'app_settings',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (rows.isEmpty) {
      // This should never happen given the INSERT OR IGNORE above.
      // If it does, something is wrong with the schema — throw so that
      // Crashlytics captures a fatal event rather than silently proceeding
      // with a broken settings state.
      throw StateError(
        'AppSettingsInitializer: app_settings singleton row missing after insert. '
        'Schema may be corrupt.',
      );
    }

    final row = rows.first;
    dev.log(
      'AppSettingsInitializer: singleton confirmed — '
      'dialect=${row['dialect_pref']}, '
      'theme=${row['theme_pref']}, '
      'onboarding_done=${row['onboarding_done']}, '
      'pro_cache=${row['pro_entitlement_cache']}',
      name: 'Tazakar.DB',
    );
  }
}
