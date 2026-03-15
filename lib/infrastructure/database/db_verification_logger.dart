import 'dart:developer' as dev;

import 'package:sqflite/sqflite.dart';

// ---------------------------------------------------------------------------
// DbVerificationLogger
// ---------------------------------------------------------------------------
//
// Debug-only helper that logs the state of the database immediately after
// DatabaseService.init() completes.
//
// Output per run:
//   • List of all tables present in the schema
//   • Row count for each table
//   • Full contents of app_settings (singleton row)
//   • First 8 categories (id, name_ar, name_en, sort_order)
//   • A PASS / FAIL verdict against the expected Sprint 3.2 baseline
//
// How it is invoked (in database_service.dart):
//
//   assert(() {
//     DbVerificationLogger.log(_db);
//     return true;
//   }());
//
// The assert wrapper means this code is compiled out entirely in release
// builds — zero performance and zero binary-size impact in production.
// flutter run --release will never execute a single line of this file.
//
// Expected baseline (Sprint 3.2):
//   tables       : 6  (categories, reminders, recurrence_rules,
//                      notifications, audit_log, app_settings)
//   categories   : 8  (all system-seeded)
//   app_settings : 1  (singleton)
//   reminders    : 0  (none yet — Sprint 3.3+)
//   recurrence_rules : 0
//   notifications    : 0
//   audit_log        : 0
// ---------------------------------------------------------------------------

class DbVerificationLogger {
  DbVerificationLogger._();

  // Expected state after a clean Sprint 3.2 init.
  static const _expectedTables = 6;
  static const _expectedCategories = 8;
  static const _expectedAppSettings = 1;

  static const _allTables = [
    'categories',
    'reminders',
    'recurrence_rules',
    'notifications',
    'audit_log',
    'app_settings',
  ];

  /// Logs full DB verification output to the debug console.
  /// Must only be called from inside an assert block.
  static Future<void> log(Database db) async {
    dev.log(_divider('DB VERIFICATION — Sprint 3.2'), name: 'Tazakar.DB');

    // ── 1. Table list ──────────────────────────────────────────────────────
    final tableRows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name;",
    );
    final presentTables = tableRows.map((r) => r['name'] as String).toList();

    dev.log('Tables present (${presentTables.length}):', name: 'Tazakar.DB');
    for (final t in presentTables) {
      dev.log('  • $t', name: 'Tazakar.DB');
    }

    // ── 2. Row counts ──────────────────────────────────────────────────────
    dev.log(_divider('ROW COUNTS'), name: 'Tazakar.DB');

    final counts = <String, int>{};
    for (final table in _allTables) {
      final result = await db.rawQuery('SELECT COUNT(*) AS c FROM $table;');
      counts[table] = (result.first['c'] as int?) ?? 0;
      dev.log('  $table: ${counts[table]}', name: 'Tazakar.DB');
    }

    // ── 3. app_settings contents ───────────────────────────────────────────
    dev.log(_divider('app_settings'), name: 'Tazakar.DB');

    final settingsRows = await db.query('app_settings', limit: 1);
    if (settingsRows.isNotEmpty) {
      final s = settingsRows.first;
      dev.log('  id                    : ${s['id']}', name: 'Tazakar.DB');
      dev.log('  dialect_pref          : ${s['dialect_pref']}', name: 'Tazakar.DB');
      dev.log('  theme_pref            : ${s['theme_pref']}', name: 'Tazakar.DB');
      dev.log('  onboarding_done       : ${s['onboarding_done']}', name: 'Tazakar.DB');
      dev.log('  pro_entitlement_cache : ${s['pro_entitlement_cache']}', name: 'Tazakar.DB');
      dev.log('  last_rc_fetch         : ${s['last_rc_fetch'] ?? 'NULL'}', name: 'Tazakar.DB');
      dev.log('  updated_at            : ${_fmtMs(s['updated_at'])}', name: 'Tazakar.DB');
    } else {
      dev.log('  !! NO ROW FOUND !!', name: 'Tazakar.DB');
    }

    // ── 4. Categories preview ──────────────────────────────────────────────
    dev.log(_divider('CATEGORIES (first 8)'), name: 'Tazakar.DB');

    final cats = await db.query(
      'categories',
      columns: ['id', 'name_ar', 'name_en', 'icon_code', 'color_hex', 'sort_order'],
      orderBy: 'sort_order ASC',
      limit: 8,
    );
    for (final c in cats) {
      dev.log(
        '  [${c['sort_order']}] ${c['name_ar']} / ${c['name_en']}'
        '  icon=${c['icon_code']}  color=${c['color_hex']}',
        name: 'Tazakar.DB',
      );
    }

    // ── 5. PASS / FAIL verdict ─────────────────────────────────────────────
    dev.log(_divider('VERDICT'), name: 'Tazakar.DB');

    final checks = <String, bool>{
      'Table count = $_expectedTables':
          presentTables.length == _expectedTables,
      'All expected tables present':
          _allTables.every((t) => presentTables.contains(t)),
      'categories = $_expectedCategories':
          counts['categories'] == _expectedCategories,
      'app_settings = $_expectedAppSettings':
          counts['app_settings'] == _expectedAppSettings,
      'reminders = 0': counts['reminders'] == 0,
      'recurrence_rules = 0': counts['recurrence_rules'] == 0,
      'notifications = 0': counts['notifications'] == 0,
      'audit_log = 0': counts['audit_log'] == 0,
    };

    var allPassed = true;
    for (final entry in checks.entries) {
      final icon = entry.value ? '✓' : '✗';
      dev.log('  $icon ${entry.key}', name: 'Tazakar.DB');
      if (!entry.value) allPassed = false;
    }

    dev.log(
      allPassed
          ? '  ✅ ALL CHECKS PASSED — Sprint 3.2 DB baseline confirmed.'
          : '  ❌ ONE OR MORE CHECKS FAILED — review output above.',
      name: 'Tazakar.DB',
    );

    dev.log(_divider('END'), name: 'Tazakar.DB');
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  static String _divider(String label) =>
      '────────── $label ──────────';

  static String _fmtMs(dynamic ms) {
    if (ms == null) return 'NULL';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms as int, isUtc: true);
    return dt.toIso8601String();
  }
}
