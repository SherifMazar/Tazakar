// lib/features/reminder/data/datasources/local/reminder_dao.dart
//
// DEC-30: id is INTEGER — use int throughout.

import 'package:sqflite_common/sqlite_api.dart';
import '../../../../../core/database/database_helper.dart';
import '../../models/reminder_model.dart';
import 'reminder_mapper.dart';

class ReminderDao {
  static const String _table = 'reminders';

  Future<Database> get _db async => DatabaseHelper.instance.database;

  // ── Create ──────────────────────────────────────────────────────────────

  /// Inserts a new reminder and returns the row id assigned by AUTOINCREMENT.
  Future<int> insert(ReminderModel reminder) async {
    final db = await _db;
    final map = ReminderMapper.toMap(reminder);
    map.remove('id'); // never supply id on insert
    return db.insert(
      _table,
      map,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<ReminderModel?> findById(int id) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ReminderModel.fromEntity(ReminderMapper.fromMap(rows.first));
  }

  Future<List<ReminderModel>> findAll() async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'is_deleted = 0',
      orderBy: 'remind_at ASC',
    );
    return rows
        .map((r) => ReminderModel.fromEntity(ReminderMapper.fromMap(r)))
        .toList();
  }

  Future<int> countActive() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_table WHERE is_deleted = 0 AND is_completed = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ── Update ───────────────────────────────────────────────────────────────

  Future<int> update(ReminderModel reminder) async {
    final db = await _db;
    return db.update(
      _table,
      ReminderMapper.toMap(reminder),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  // ── Soft delete ───────────────────────────────────────────────────────────

  Future<int> softDelete(int id) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.update(
      _table,
      {'is_deleted': 1, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Snooze (Sprint 3.6) ──────────────────────────────────────────────────

  /// Pushes remind_at forward by [duration] from now.
  Future<int> snooze(int id, Duration duration) async {
    final db = await _db;
    final newRemindAt =
        DateTime.now().add(duration).millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.update(
      _table,
      {'remind_at': newRemindAt, 'updated_at': now},
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
  }
}
