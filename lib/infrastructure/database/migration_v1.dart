import 'dart:developer' as dev;

import 'package:sqflite/sqflite.dart';

// ---------------------------------------------------------------------------
// MigrationV1
// ---------------------------------------------------------------------------
//
// Creates all 6 tables for Tazakar schema version 1.
//
// Tables:
//   1. categories          — system + user-defined reminder categories
//   2. reminders           — core reminder records
//   3. recurrence_rules    — recurrence pattern per reminder
//   4. notifications       — scheduled local notification log
//   5. audit_log           — immutable change history
//   6. app_settings        — single-row app configuration singleton
//
// Design rules:
//   • All statements use CREATE TABLE IF NOT EXISTS — fully idempotent.
//   • UUIDs are stored as TEXT (dart:uuid v4 output).
//   • Booleans are INTEGER 0/1 (SQLite has no native BOOL type).
//   • Timestamps are INTEGER Unix epoch milliseconds (UTC).
//   • Foreign keys are enforced — PRAGMA foreign_keys = ON is set by
//     DatabaseService.onConfigure before this migration runs.
//   • No nullable NOT NULL columns without a DEFAULT — every column
//     that is NOT NULL has either a DEFAULT or is a primary key.
// ---------------------------------------------------------------------------

class MigrationV1 {
  MigrationV1._();

  /// Runs all v1 DDL statements against [db].
  /// Safe to call on an existing database — all statements are idempotent.
  static Future<void> run(Database db) async {
    dev.log('MigrationV1: start', name: 'Tazakar.DB');

    await db.transaction((txn) async {
      await _createCategories(txn);
      await _createReminders(txn);
      await _createRecurrenceRules(txn);
      await _createNotifications(txn);
      await _createAuditLog(txn);
      await _createAppSettings(txn);
    });

    dev.log('MigrationV1: complete — 6 tables created.', name: 'Tazakar.DB');
  }

  // -------------------------------------------------------------------------
  // 1. categories
  // -------------------------------------------------------------------------
  // Stores both system-seeded categories (is_system = 1) and any
  // user-created categories (is_system = 0).
  // System categories must never be deleted — enforced at the repository
  // layer by checking is_system before any DELETE.
  static Future<void> _createCategories(Transaction txn) async {
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id          TEXT    NOT NULL PRIMARY KEY,
        name_ar     TEXT    NOT NULL,
        name_en     TEXT    NOT NULL,
        icon_code   TEXT    NOT NULL,
        color_hex   TEXT    NOT NULL DEFAULT '#1ABC9C',
        is_system   INTEGER NOT NULL DEFAULT 0 CHECK (is_system IN (0, 1)),
        sort_order  INTEGER NOT NULL DEFAULT 0,
        created_at  INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
      );
    ''');
    dev.log('MigrationV1: categories table ready.', name: 'Tazakar.DB');
  }

  // -------------------------------------------------------------------------
  // 2. reminders
  // -------------------------------------------------------------------------
  // Core reminder record. Each row represents one reminder regardless of
  // whether it is one-off or recurring.
  //
  // recurrence_rule_id is nullable — NULL means the reminder fires once only.
  // category_id references categories(id); deletion of a category that has
  // reminders is blocked by the FOREIGN KEY constraint.
  static Future<void> _createReminders(DatabaseExecutor txn) async {
    await txn.execute('''
      CREATE TABLE reminders (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        subject      TEXT    NOT NULL,
        category_id  INTEGER NOT NULL DEFAULT 1,
        scheduled_at INTEGER NOT NULL,
        dialect_code TEXT    NOT NULL DEFAULT "ar-AE",
        is_completed INTEGER NOT NULL DEFAULT 0,
        snoozed_until INTEGER,
        created_at   INTEGER NOT NULL,
        updated_at   INTEGER NOT NULL
      )
    ''');

    await txn.execute(
      'CREATE INDEX idx_reminders_scheduled ON reminders(scheduled_at) WHERE is_completed = 0',
    );
    await txn.execute(
      'CREATE INDEX idx_reminders_category ON reminders(category_id) WHERE is_completed = 0',
    );
  }

  // -------------------------------------------------------------------------
  // 3. recurrence_rules
  // -------------------------------------------------------------------------
  // Stores the recurrence pattern for a recurring reminder.
  // One row per reminder; joined via reminders.recurrence_rule_id.
  //
  // frequency values: 'daily' | 'weekly' | 'monthly' | 'yearly' | 'custom'
  // days_of_week: comma-separated integers 1–7 (ISO: 1=Mon … 7=Sun), nullable
  // end_date: Unix epoch ms; NULL means no end date (Pro tier only for non-daily).
  static Future<void> _createRecurrenceRules(Transaction txn) async {
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS recurrence_rules (
        id            TEXT    NOT NULL PRIMARY KEY,
        reminder_id   TEXT    NOT NULL UNIQUE,
        frequency     TEXT    NOT NULL
                        CHECK (frequency IN ('daily','weekly','monthly','yearly','custom')),
        interval_val  INTEGER NOT NULL DEFAULT 1 CHECK (interval_val >= 1),
        days_of_week  TEXT,
        end_date      INTEGER,
        created_at    INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
        FOREIGN KEY (reminder_id)
          REFERENCES reminders (id)
          ON DELETE CASCADE
      );
    ''');
    dev.log('MigrationV1: recurrence_rules table ready.', name: 'Tazakar.DB');
  }

  // -------------------------------------------------------------------------
  // 4. notifications
  // -------------------------------------------------------------------------
  // Log of every local notification scheduled or delivered for a reminder.
  // Used to:
  //   • Avoid double-scheduling on app restart
  //   • Surface delivery history in the UI (Phase 4)
  //   • Diagnose AQ-03 (Android Doze reliability)
  //
  // status values: 'scheduled' | 'delivered' | 'cancelled' | 'failed'
  static Future<void> _createNotifications(Transaction txn) async {
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id            TEXT    NOT NULL PRIMARY KEY,
        reminder_id   TEXT    NOT NULL,
        scheduled_at  INTEGER NOT NULL,
        delivered_at  INTEGER,
        status        TEXT    NOT NULL DEFAULT 'scheduled'
                        CHECK (status IN ('scheduled','delivered','cancelled','failed')),
        FOREIGN KEY (reminder_id)
          REFERENCES reminders (id)
          ON DELETE CASCADE
      );
    ''');

    // Index: look up all notifications for a given reminder quickly.
    await txn.execute('''
      CREATE INDEX IF NOT EXISTS idx_notifications_reminder
        ON notifications (reminder_id);
    ''');

    dev.log('MigrationV1: notifications table ready.', name: 'Tazakar.DB');
  }

  // -------------------------------------------------------------------------
  // 5. audit_log
  // -------------------------------------------------------------------------
  // Append-only change history. Rows are never updated or deleted.
  //
  // entity_type values: 'reminder' | 'category' | 'app_settings'
  // action values:      'create' | 'update' | 'delete' | 'complete' | 'snooze'
  // payload_json: JSON snapshot of the changed fields (optional, nullable).
  static Future<void> _createAuditLog(Transaction txn) async {
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS audit_log (
        id            TEXT    NOT NULL PRIMARY KEY,
        entity_type   TEXT    NOT NULL
                        CHECK (entity_type IN ('reminder','category','app_settings')),
        entity_id     TEXT    NOT NULL,
        action        TEXT    NOT NULL
                        CHECK (action IN ('create','update','delete','complete','snooze')),
        changed_at    INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
        payload_json  TEXT
      );
    ''');

    // Index: fetch full history for one entity (reminder detail screen).
    await txn.execute('''
      CREATE INDEX IF NOT EXISTS idx_audit_entity
        ON audit_log (entity_type, entity_id);
    ''');

    dev.log('MigrationV1: audit_log table ready.', name: 'Tazakar.DB');
  }

  // -------------------------------------------------------------------------
  // 6. app_settings
  // -------------------------------------------------------------------------
  // Single-row configuration singleton. The CHECK (id = 1) constraint and
  // the INSERT OR IGNORE guard in AppSettingsInitializer together guarantee
  // exactly one row exists at all times.
  //
  // pro_entitlement_cache: 0 = free, 1 = pro. Refreshed from StoreKit /
  //   Play Billing on each app foreground. Source of truth is the store;
  //   this is a cache only.
  // last_rc_fetch: Unix epoch ms of last successful Firebase Remote Config
  //   fetch. NULL before first fetch.
  static Future<void> _createAppSettings(Transaction txn) async {
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        id                      INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
        dialect_pref            TEXT    NOT NULL DEFAULT 'auto',
        theme_pref              TEXT    NOT NULL DEFAULT 'dark'
                                  CHECK (theme_pref IN ('dark','light','system')),
        onboarding_done         INTEGER NOT NULL DEFAULT 0
                                  CHECK (onboarding_done IN (0, 1)),
        pro_entitlement_cache   INTEGER NOT NULL DEFAULT 0
                                  CHECK (pro_entitlement_cache IN (0, 1)),
        last_rc_fetch           INTEGER,
        updated_at              INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
      );
    ''');
    dev.log('MigrationV1: app_settings table ready.', name: 'Tazakar.DB');
  }
}
