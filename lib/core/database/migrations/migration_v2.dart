// lib/core/database/migrations/migration_v2.dart
//
// DEC-30: Migrate reminders.id from TEXT (UUID) to
//         INTEGER PRIMARY KEY AUTOINCREMENT.
// DEC-31: Create notification_audit table (F-N07/F-N08).
//
// Column names match schema v1 (_onCreate in database_helper.dart):
//   subject, category_id, scheduled_at, dialect_code,
//   is_completed, snoozed_until, created_at, updated_at

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV2 {
  static const int version = 2;

  static Future<void> migrate(Database db) async {
    await db.transaction((txn) async {
      // ── (a) Recreate reminders with INTEGER PK ──────────────────────────
      await txn.execute('''
        CREATE TABLE reminders_v2 (
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

      // Copy all rows — drop the old TEXT pk, AUTOINCREMENT assigns new ids
      await txn.execute('''
        INSERT INTO reminders_v2
          (subject, category_id, scheduled_at, dialect_code,
           is_completed, snoozed_until, created_at, updated_at)
        SELECT
          subject, category_id, scheduled_at, dialect_code,
          is_completed, snoozed_until, created_at, updated_at
        FROM reminders
      ''');

      await txn.execute('DROP TABLE reminders');
      await txn.execute('ALTER TABLE reminders_v2 RENAME TO reminders');

      // ── (b) Create notification_audit table ─────────────────────────────
      await txn.execute('''
        CREATE TABLE notification_audit (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          reminder_id INTEGER NOT NULL,
          event       TEXT    NOT NULL,
          occurred_at INTEGER NOT NULL,
          meta        TEXT
        )
      ''');

      await txn.execute(
        'CREATE INDEX idx_audit_reminder ON notification_audit(reminder_id)',
      );
    });

    debugPrint('[MigrationV2] Complete — INTEGER pk + notification_audit created.');
  }
}
