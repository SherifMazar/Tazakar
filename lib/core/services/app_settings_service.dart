import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

// ---------------------------------------------------------------------------
// AppSettingsService
// ---------------------------------------------------------------------------
//
// Reads and writes the singleton row in the app_settings table.
//
// Schema (defined in migration_v1.dart):
//   id                    INTEGER  PRIMARY KEY CHECK (id = 1)
//   dialect_pref          TEXT     NOT NULL DEFAULT 'auto'
//   theme_pref            TEXT     NOT NULL DEFAULT 'dark'
//                           CHECK (theme_pref IN ('dark','light','system'))
//   onboarding_done       INTEGER  NOT NULL DEFAULT 0
//   pro_entitlement_cache INTEGER  NOT NULL DEFAULT 0
//   last_rc_fetch         INTEGER  (nullable)
//   updated_at            INTEGER  NOT NULL
//
// All reads query WHERE id = 1.
// All writes use UPDATE ... WHERE id = 1.
// ---------------------------------------------------------------------------

class AppSettingsService {
  static const _table = 'app_settings';
  static const _id = 1;

  // ── helpers ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _row(Database db) async {
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [_id],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<void> _update(Database db, Map<String, dynamic> values) async {
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    await db.update(
      _table,
      {...values, 'updated_at': nowMs},
      where: 'id = ?',
      whereArgs: [_id],
    );
  }

  // ── theme ─────────────────────────────────────────────────────────────────

  Future<ThemeMode> getThemeMode(Database db) async {
    final row = await _row(db);
    switch (row?['theme_pref'] as String?) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(Database db, ThemeMode mode) async {
    final String pref;
    switch (mode) {
      case ThemeMode.light:
        pref = 'light';
        break;
      case ThemeMode.dark:
        pref = 'dark';
        break;
      case ThemeMode.system:
        pref = 'system';
        break;
    }
    await _update(db, {'theme_pref': pref});
  }

  // ── dialect ───────────────────────────────────────────────────────────────

  Future<String> getDialectPref(Database db) async {
    final row = await _row(db);
    return (row?['dialect_pref'] as String?) ?? 'auto';
  }

  Future<void> setDialectPref(Database db, String dialectCode) async {
    await _update(db, {'dialect_pref': dialectCode});
  }

  // ── onboarding ────────────────────────────────────────────────────────────

  Future<bool> isOnboardingDone(Database db) async {
    final row = await _row(db);
    return (row?['onboarding_done'] as int? ?? 0) == 1;
  }

  Future<void> markOnboardingDone(Database db) async {
    await _update(db, {'onboarding_done': 1});
  }

  // ── pro entitlement cache ────────────────────────────────────────────────

  Future<bool> isProEntitled(Database db) async {
    final row = await _row(db);
    return (row?['pro_entitlement_cache'] as int? ?? 0) == 1;
  }

  Future<void> setProEntitlement(Database db, {required bool isPro}) async {
    await _update(db, {'pro_entitlement_cache': isPro ? 1 : 0});
  }

  // ── Remote Config fetch timestamp ────────────────────────────────────────

  Future<DateTime?> getLastRcFetch(Database db) async {
    final row = await _row(db);
    final ms = row?['last_rc_fetch'] as int?;
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true) : null;
  }

  Future<void> setLastRcFetch(Database db, DateTime fetchTime) async {
    await _update(db, {'last_rc_fetch': fetchTime.toUtc().millisecondsSinceEpoch});
  }

  // ── Legacy shims (kept for call-site compatibility) ───────────────────────

  /// @deprecated Use [isOnboardingDone] instead.
  Future<bool> isFirstLaunch(Database db) async {
    return !(await isOnboardingDone(db));
  }

  /// @deprecated Use [markOnboardingDone] instead.
  Future<void> markLaunched(Database db) async {
    await markOnboardingDone(db);
  }

  /// @deprecated Use [getDialectPref] instead.
  Future<String> getLanguageCode(Database db) async {
    return getDialectPref(db);
  }

  /// @deprecated Snooze duration is now a per-reminder field, not a global setting.
  Future<int> getSnoozeDuration(Database db) async => 10;
}

final appSettingsServiceProvider = Provider<AppSettingsService>((ref) {
  return AppSettingsService();
});
