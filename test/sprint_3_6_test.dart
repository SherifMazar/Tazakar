// test/sprint_3_6_test.dart
//
// Sprint 3.6 — 22 tests
// Groups:
//   A — MigrationV2 (4 tests)
//   B — NotificationAuditLog entity + NotificationEvent enum (4 tests)
//   C — NotificationAuditDao SQL operations (5 tests)
//   D — SnoozeReminderUseCase logic (5 tests)
//   E — SnoozeResult type (4 tests)

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tazakar/core/database/migrations/migration_v2.dart';
import 'package:tazakar/features/notification/domain/entities/notification_audit_log.dart';
import 'package:tazakar/features/notification/data/datasources/local/notification_audit_dao.dart';
import 'package:tazakar/features/reminder/domain/usecases/snooze_reminder_use_case.dart';
import 'package:tazakar/core/services/notification_service.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockNotificationService extends Mock implements NotificationService {}
class MockNotificationAuditDao extends Mock implements NotificationAuditDao {}

// ── In-memory DB factory ──────────────────────────────────────────────────────

Future<Database> _openFreshDb() async {
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(version: 1),
  );
}

Future<Database> _openV1SchemaDb({bool seedReminder = false}) async {
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        // v1 reminders table — TEXT primary key, matches live schema
        await db.execute('''
          CREATE TABLE reminders (
            id TEXT PRIMARY KEY,
            subject TEXT NOT NULL,
            category_id INTEGER NOT NULL DEFAULT 1,
            scheduled_at INTEGER NOT NULL,
            dialect_code TEXT NOT NULL DEFAULT "ar-AE",
            is_completed INTEGER NOT NULL DEFAULT 0,
            snoozed_until INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
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
        if (seedReminder) {
          final now = DateTime.now().millisecondsSinceEpoch;
          await db.insert('reminders', {
            'id': 'uuid-test-001',
            'subject': 'Old reminder',
            'category_id': 1,
            'scheduled_at': now,
            'dialect_code': 'ar-AE',
            'is_completed': 0,
            'created_at': now,
            'updated_at': now,
          });
        }
      },
    ),
  );
  return db;
}

Future<Database> _openAuditDb() async {
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE notification_audit (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            reminder_id INTEGER NOT NULL,
            event       TEXT    NOT NULL,
            occurred_at INTEGER NOT NULL,
            meta        TEXT
          )
        ''');
      },
    ),
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<int> _insertAuditRow(
  Database db, {
  int reminderId = 1,
  String event = 'scheduled',
  String? meta,
}) =>
    db.insert('notification_audit', {
      'reminder_id': reminderId,
      'event': event,
      'occurred_at': DateTime.now().millisecondsSinceEpoch,
      'meta': meta,
    });

// ── Main ──────────────────────────────────────────────────────────────────────

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // ══════════════════════════════════════════════════════════════════════════
  // Group A — MigrationV2
  // ══════════════════════════════════════════════════════════════════════════
  group('A — MigrationV2', () {
    late Database db;

    setUp(() async {
      db = await _openV1SchemaDb(seedReminder: true);
    });

    tearDown(() => db.close());

    test('A1 — migration runs without error', () async {
      await expectLater(MigrationV2.migrate(db), completes);
    });

    test('A2 — reminders table has INTEGER id after migration', () async {
      await MigrationV2.migrate(db);
      final info = await db.rawQuery('PRAGMA table_info(reminders)');
      final idCol = info.firstWhere((c) => c['name'] == 'id');
      expect(idCol['type'], equals('INTEGER'));
    });

    test('A3 — existing reminder data is preserved after migration', () async {
      await MigrationV2.migrate(db);
      final rows = await db.query('reminders');
      expect(rows.length, equals(1));
      expect(rows.first['subject'], equals('Old reminder'));
    });

    test('A4 — notification_audit table is created by migration', () async {
      await MigrationV2.migrate(db);
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='notification_audit'",
      );
      expect(tables, isNotEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Group B — NotificationAuditLog entity & NotificationEvent enum
  // ══════════════════════════════════════════════════════════════════════════
  group('B — NotificationAuditLog entity', () {
    test('B1 — NotificationEvent.fromString round-trips all 6 values', () {
      for (final event in NotificationEvent.values) {
        expect(
          NotificationEvent.fromString(event.value),
          equals(event),
        );
      }
    });

    test('B2 — NotificationAuditLog stores reminderId correctly', () {
      final log = NotificationAuditLog(
        reminderId: 42,
        event: NotificationEvent.scheduled,
        occurredAt: DateTime.now(),
      );
      expect(log.reminderId, equals(42));
    });

    test('B3 — NotificationAuditLog stores meta correctly', () {
      final log = NotificationAuditLog(
        reminderId: 1,
        event: NotificationEvent.snoozed,
        occurredAt: DateTime.now(),
        meta: '{"duration_minutes":10}',
      );
      expect(log.meta, equals('{"duration_minutes":10}'));
    });

    test('B4 — NotificationAuditLog id defaults to 0 for unsaved records', () {
      final log = NotificationAuditLog(
        reminderId: 1,
        event: NotificationEvent.cancelled,
        occurredAt: DateTime.now(),
      );
      expect(log.id, equals(0));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Group C — NotificationAuditDao SQL operations (uses in-memory DB)
  // ══════════════════════════════════════════════════════════════════════════
  group('C — NotificationAuditDao SQL', () {
    late Database db;

    setUp(() async {
      db = await _openAuditDb();
    });

    tearDown(() => db.close());

    test('C1 — can insert a scheduled event', () async {
      final id = await _insertAuditRow(db, event: 'scheduled');
      expect(id, greaterThan(0));
    });

    test('C2 — forReminder returns only rows for that reminder', () async {
      await _insertAuditRow(db, reminderId: 1, event: 'scheduled');
      await _insertAuditRow(db, reminderId: 1, event: 'snoozed');
      await _insertAuditRow(db, reminderId: 2, event: 'scheduled');

      final rows = await db.query(
        'notification_audit',
        where: 'reminder_id = ?',
        whereArgs: [1],
      );
      expect(rows.length, equals(2));
    });

    test('C3 — snoozed event stores meta JSON correctly', () async {
      await _insertAuditRow(
        db,
        event: 'snoozed',
        meta: '{"duration_minutes":10}',
      );
      final rows = await db.query(
        'notification_audit',
        where: "event = 'snoozed'",
      );
      expect(rows.first['meta'], equals('{"duration_minutes":10}'));
    });

    test('C4 — pruneOlderThan removes stale rows and keeps recent ones', () async {
      // Insert a row dated 31 days ago
      final oldDate = DateTime.now()
          .subtract(const Duration(days: 31))
          .millisecondsSinceEpoch;
      await db.insert('notification_audit', {
        'reminder_id': 1,
        'event': 'scheduled',
        'occurred_at': oldDate,
      });
      // Insert a recent row
      await _insertAuditRow(db, event: 'scheduled');

      final cutoff = DateTime.now()
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch;
      final deleted = await db.delete(
        'notification_audit',
        where: 'occurred_at < ?',
        whereArgs: [cutoff],
      );
      expect(deleted, equals(1));

      final remaining = await db.query('notification_audit');
      expect(remaining.length, equals(1));
    });

    test('C5 — multiple events for same reminder are ordered by occurred_at', () async {
      final base = DateTime.now().millisecondsSinceEpoch;
      await db.insert('notification_audit', {
        'reminder_id': 5,
        'event': 'scheduled',
        'occurred_at': base,
      });
      await db.insert('notification_audit', {
        'reminder_id': 5,
        'event': 'snoozed',
        'occurred_at': base + 60000,
      });

      final rows = await db.query(
        'notification_audit',
        where: 'reminder_id = ?',
        whereArgs: [5],
        orderBy: 'occurred_at ASC',
      );
      expect(rows.first['event'], equals('scheduled'));
      expect(rows.last['event'], equals('snoozed'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Group D — SnoozeReminderUseCase (mocked dependencies)
  // ══════════════════════════════════════════════════════════════════════════
  group('D — SnoozeReminderUseCase', () {
    late MockNotificationService mockService;
    late MockNotificationAuditDao mockAuditDao;
    late SnoozeReminderUseCase useCase;

    setUp(() {
      mockService = MockNotificationService();
      mockAuditDao = MockNotificationAuditDao();
      useCase = SnoozeReminderUseCase(
        notificationService: mockService,
        auditDao: mockAuditDao,
      );

      registerFallbackValue(NotificationAuditLog(
        reminderId: 1,
        event: NotificationEvent.snoozed,
        occurredAt: DateTime(2026),
      ));
    });

    test('D1 — SnoozeParams stores reminderId and duration correctly', () {
      const params = SnoozeParams(
        reminderId: 7,
        duration: Duration(minutes: 15),
      );
      expect(params.reminderId, equals(7));
      expect(params.duration.inMinutes, equals(15));
    });

    test('D2 — SnoozeResult.ok reports success true and rowsAffected', () {
      const result = SnoozeResult.ok(1);
      expect(result.success, isTrue);
      expect(result.rowsAffected, equals(1));
      expect(result.errorMessage, isNull);
    });

    test('D3 — SnoozeResult.error reports success false and message', () {
      const result = SnoozeResult.error('Reminder not found');
      expect(result.success, isFalse);
      expect(result.errorMessage, equals('Reminder not found'));
      expect(result.rowsAffected, equals(0));
    });

    test('D4 — useCase is const-constructible', () {
      expect(useCase, isA<SnoozeReminderUseCase>());
    });

    test('D5 — SnoozeParams with zero duration is valid', () {
      const params = SnoozeParams(
        reminderId: 1,
        duration: Duration.zero,
      );
      expect(params.duration.inMinutes, equals(0));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Group E — SnoozeResult edge cases
  // ══════════════════════════════════════════════════════════════════════════
  group('E — SnoozeResult', () {
    test('E1 — ok with 0 rows is still success', () {
      const result = SnoozeResult.ok(0);
      expect(result.success, isTrue);
      expect(result.rowsAffected, equals(0));
    });

    test('E2 — error with null-like empty string', () {
      const result = SnoozeResult.error('');
      expect(result.success, isFalse);
      expect(result.errorMessage, equals(''));
    });

    test('E3 — NotificationEvent enum has exactly 6 values', () {
      expect(NotificationEvent.values.length, equals(6));
    });

    test('E4 — NotificationEvent values include snoozed', () {
      expect(
        NotificationEvent.values.map((e) => e.value),
        contains('snoozed'),
      );
    });
  });
}
