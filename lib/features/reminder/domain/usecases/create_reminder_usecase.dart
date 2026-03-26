import 'package:tazakar/core/services/feature_gate/feature_gate_service.dart';
import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';

/// Failure types surfaced to the presentation layer.
enum CreateReminderFailure {
  freeTierCapReached,
  recurrenceNotAllowed,
  invalidTitle,
  invalidScheduledAt,
}

sealed class CreateReminderResult {
  const CreateReminderResult();
}

final class CreateReminderSuccess extends CreateReminderResult {
  const CreateReminderSuccess(this.id);
  final int id;
}

final class CreateReminderFailureResult extends CreateReminderResult {
  const CreateReminderFailureResult(this.failure);
  final CreateReminderFailure failure;
}

class CreateReminderUseCase {
  const CreateReminderUseCase({
    required this.repository,
    required this.featureGate,
  });

  final ReminderRepository repository;
  final FeatureGateService featureGate;

  Future<CreateReminderResult> execute(Reminder reminder) async {
    // Guard: title must not be empty.
    if (reminder.title.trim().isEmpty) {
      return const CreateReminderFailureResult(
        CreateReminderFailure.invalidTitle,
      );
    }

    // Guard: scheduled time must be in the future.
    if (reminder.remindAt.isBefore(DateTime.now())) {
      return const CreateReminderFailureResult(
        CreateReminderFailure.invalidScheduledAt,
      );
    }

    // Guard: free-tier cap (DEC-22 — 10 reminders).
    final canCreate = featureGate.canCreateReminder(
      await repository.count(),
    );
    if (!canCreate) {
      return const CreateReminderFailureResult(
        CreateReminderFailure.freeTierCapReached,
      );
    }

    // Guard: recurrence tier check (DEC-26).
    final allowedTypes = featureGate.availableRecurrenceOptions;
    if (!allowedTypes.contains(reminder.recurrence)) {
      return const CreateReminderFailureResult(
        CreateReminderFailure.recurrenceNotAllowed,
      );
    }

    final id = await repository.create(reminder);
    return CreateReminderSuccess(id);
  }
}
