import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';

// ── Read ──────────────────────────────────────────────────────────────────────

class ReadReminderUseCase {
  const ReadReminderUseCase(this.repository);
  final ReminderRepository repository;

  Future<Reminder?> execute(String id) => repository.readById(id);
}

class ReadAllRemindersUseCase {
  const ReadAllRemindersUseCase(this.repository);
  final ReminderRepository repository;

  Future<List<Reminder>> execute() => repository.readAll();
}

class ReadActiveRemindersUseCase {
  const ReadActiveRemindersUseCase(this.repository);
  final ReminderRepository repository;

  Future<List<Reminder>> execute() => repository.readActive();
}

// ── Update ────────────────────────────────────────────────────────────────────

class UpdateReminderUseCase {
  const UpdateReminderUseCase(this.repository);
  final ReminderRepository repository;

  Future<void> execute(Reminder reminder) async {
    assert(reminder.id != null, 'Cannot update a reminder without an id');
    await repository.update(reminder);
  }
}

// ── Delete ────────────────────────────────────────────────────────────────────

class DeleteReminderUseCase {
  const DeleteReminderUseCase(this.repository);
  final ReminderRepository repository;

  /// Soft-delete only (sets is_completed = 1).
  Future<void> execute(String id) => repository.delete(id);
}
