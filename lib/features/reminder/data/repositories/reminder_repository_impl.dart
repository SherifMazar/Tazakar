import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/reminder_dao.dart';
import '../mappers/reminder_mapper.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  const ReminderRepositoryImpl(this._dao);

  final ReminderDao _dao;

  @override
  Future<int> create(Reminder reminder) async {
    final row = ReminderMapper.toRow(reminder);
    return _dao.insert(row);
  }

  @override
  Future<Reminder?> readById(int id) async {
    final row = await _dao.queryById(id);
    return row == null ? null : ReminderMapper.fromRow(row);
  }

  @override
  Future<List<Reminder>> readAll() async {
    final rows = await _dao.queryAll();
    return rows.map(ReminderMapper.fromRow).toList();
  }

  @override
  Future<List<Reminder>> readActive() async {
    // queryAll already filters is_completed = 0.
    return readAll();
  }

  @override
  Future<void> update(Reminder reminder) async {
    assert(reminder.id != null, 'Cannot update a reminder without an id');
    final row = ReminderMapper.toRow(
      reminder.copyWith(updatedAt: DateTime.now()),
    );
    await _dao.update(row);
  }

  @override
  Future<void> delete(int id) async {
    await _dao.softDelete(id);
  }

  @override
  Future<void> deleteAll() async {
    await _dao.deleteAll();
  }

  @override
  Future<int> count() => _dao.count();
}
