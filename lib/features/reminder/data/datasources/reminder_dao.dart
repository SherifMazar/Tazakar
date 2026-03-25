import 'package:sqflite/sqflite.dart';
import 'package:tazakar/infrastructure/database/database_helper.dart';
import 'package:uuid/uuid.dart';

/// Raw SQLCipher access for the reminders table.
/// No domain types here — only maps in, maps out.
class ReminderDao {
  static const _table = 'reminders';
  static const _uuid = Uuid();

  Future<Database> get _db => DatabaseHelper.database;

  Future<String> insert(Map<String, dynamic> row) async {
    final db = await _db;
    final id = _uuid.v4();
    await db.insert(
      _table,
      {...row, 'id': id},
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
    return id;
  }

  Future<Map<String, dynamic>?> queryById(String id) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'id = ? AND is_completed = 0',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

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

  /// Soft-delete — sets is_completed = 1.
  Future<int> softDelete(String id) async {
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
    return firstIntValue(result) ?? 0;
  }
}
