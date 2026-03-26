import '../entities/reminder.dart';

/// Contract only — implementation lives in the data layer.
abstract interface class ReminderRepository {
  /// Persists a new reminder. Returns the assigned [id].
  Future<int> create(Reminder reminder);

  /// Returns a single reminder by [id], or null if not found.
  Future<Reminder?> readById(int id);

  /// Returns all reminders, ordered by [scheduledAt] ascending.
  Future<List<Reminder>> readAll();

  /// Returns only active (non-completed) reminders.
  Future<List<Reminder>> readActive();

  /// Persists changes to an existing reminder. Throws if [id] is null.
  Future<void> update(Reminder reminder);

  /// Soft-deletes by setting is_completed = 1.
  Future<void> delete(int id);

  /// Hard-deletes all reminders. Used in tests only.
  Future<void> deleteAll();

  /// Returns total count of all non-completed reminders.
  Future<int> count();
}
