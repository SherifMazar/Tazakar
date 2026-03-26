// lib/features/reminder/data/datasources/reminder_dao.dart
//
// Raw SQLCipher access for the reminders table.
// No domain types — only maps in, maps out.
// DEC-30: id is INTEGER PRIMARY KEY AUTOINCREMENT.

import 'package:sqflite/sqflite.dart';
import 'package:tazakar/infrastructure/database/database_helper.dart';

class ReminderDao {
  static const _table = 'reminders';

  Future<Database> get _db => DatabaseHelper.database;

  /// Inserts a new row and returns the SQLite-assigned AUTOINCREMENT id.
  Future<int> insert(Map<String, dynamic> row) async {
    final db = await _db;
    return db.insert(
      _table,
      row,
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<Map<String, dynamic>?> queryById(int id) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'id = ? AND is_completed = 0',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Returns all active (non-completed) reminders, oldest scheduled first.
  Future<List<Map<String, dynamic>>> queryAll() async {
    final db = await _db;
    return db.query(
      _table,
      where: 'is_completed = 0',
      orderBy: 'scheduled_at ASC',
    );
  }

  Future<int> update(Map<String, dynamic> row) async {
    final db = await _db;
    return db.update(
      _table,
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  /// Soft-delete: sets is_completed = 1 and stamps updated_at.
  Future<int> softDelete(int id) async {
    final db = await _db;
    return db.update(
      _table,
      {
        'is_completed': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Hard-delete all rows. Tests only.
  Future<int> deleteAll() async {
    final db = await _db;
    return db.delete(_table);
  }

  Future<int> count() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_table WHERE is_completed = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
