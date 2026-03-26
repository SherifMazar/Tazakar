import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';

// ── Read ──────────────────────────────────────────────────────────────────────

class ReadReminderUseCase {
  const ReadReminderUseCase(this.repository);
  final ReminderRepository repository;

  Future<Reminder?> execute(int id) => repository.readById(id);
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

  Future<void> execute(Reminder reminder) {
    assert(reminder.id != 0, 'Cannot update an unsaved reminder');
    return repository.update(reminder);
  }
}

// ── Delete ────────────────────────────────────────────────────────────────────

class DeleteReminderUseCase {
  const DeleteReminderUseCase(this.repository);
  final ReminderRepository repository;

  /// Soft-delete only (sets is_completed = 1).
  Future<void> execute(int id) => repository.delete(id);
}
