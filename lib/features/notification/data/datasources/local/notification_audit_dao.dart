// lib/features/notification/data/datasources/local/notification_audit_dao.dart
//
// Sprint 3.6 — F-N07/F-N08: persist notification audit events.

import 'package:sqflite/sqflite.dart';
import 'package:tazakar/infrastructure/database/database_helper.dart';
import '../../../domain/entities/notification_audit_log.dart';

class NotificationAuditDao {
  static const String _table = 'notification_audit';

  Future<Database> get _db => DatabaseHelper.database;

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<int> insert(NotificationAuditLog log) async {
    final db = await _db;
    return db.insert(_table, _toMap(log));
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<List<NotificationAuditLog>> forReminder(int reminderId) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'reminder_id = ?',
      whereArgs: [reminderId],
      orderBy: 'occurred_at ASC',
    );
    return rows.map(_fromMap).toList();
  }

  Future<List<NotificationAuditLog>> recentEvents({int limit = 50}) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      orderBy: 'occurred_at DESC',
      limit: limit,
    );
    return rows.map(_fromMap).toList();
  }

  // ── Housekeeping ──────────────────────────────────────────────────────────

  /// Deletes audit rows older than [days] days to keep DB size bounded.
  Future<int> pruneOlderThan(int days) async {
    final db = await _db;
    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    return db.delete(
      _table,
      where: 'occurred_at < ?',
      whereArgs: [cutoff],
    );
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  static Map<String, dynamic> _toMap(NotificationAuditLog log) => {
        'reminder_id': log.reminderId,
        'event': log.event.value,
        'occurred_at': log.occurredAt.millisecondsSinceEpoch,
        'meta': log.meta,
      };

  static NotificationAuditLog _fromMap(Map<String, dynamic> map) =>
      NotificationAuditLog(
        id: map['id'] as int,
        reminderId: map['reminder_id'] as int,
        event: NotificationEvent.fromString(map['event'] as String),
        occurredAt: DateTime.fromMillisecondsSinceEpoch(
          map['occurred_at'] as int,
        ),
        meta: map['meta'] as String?,
      );
}
