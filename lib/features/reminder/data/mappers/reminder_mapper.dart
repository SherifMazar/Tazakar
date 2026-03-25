import 'package:tazakar/core/services/feature_gate/feature_gate_config.dart';
import '../../domain/entities/reminder.dart';

/// Converts between [Reminder] domain entity and raw DB maps.
/// Timestamps stored as INTEGER (Unix milliseconds) per schema v1.
class ReminderMapper {
  const ReminderMapper._();

  static Map<String, dynamic> toRow(Reminder r) {
    return {
      if (r.id != null) 'id': r.id,
      'subject': r.title,
      'scheduled_at': r.scheduledAt.millisecondsSinceEpoch,
      'category_id': r.categoryId,
      'dialect_code': r.dialectCode,
      'is_completed': r.isCompleted ? 1 : 0,
      'snoozed_until': r.snoozedUntil?.millisecondsSinceEpoch,
      'created_at': r.createdAt.millisecondsSinceEpoch,
      'updated_at': r.updatedAt?.millisecondsSinceEpoch ??
          r.createdAt.millisecondsSinceEpoch,
    };
  }

  static Reminder fromRow(Map<String, dynamic> row) {
    return Reminder(
      id: row['id'] as String,
      title: row['subject'] as String,
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(
        row['scheduled_at'] as int,
      ),
      recurrenceType: RecurrenceType.none, // joined from reminder_recurrences
      categoryId: row['category_id'] as int,
      isCompleted: (row['is_completed'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at'] as int,
      ),
      snoozedUntil: row['snoozed_until'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['snoozed_until'] as int)
          : null,
      dialectCode: row['dialect_code'] as String? ?? 'ar-AE',
    );
  }
}
