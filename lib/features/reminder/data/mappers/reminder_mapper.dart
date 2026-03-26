// lib/features/reminder/data/mappers/reminder_mapper.dart
//
// Converts between [Reminder] domain entity and raw DB maps.
// Timestamps stored as INTEGER (Unix milliseconds) per schema v2.
// Schema v2 columns: id, subject, category_id, scheduled_at,
//                    dialect_code, is_completed, snoozed_until,
//                    created_at, updated_at.

import 'package:tazakar/core/services/feature_gate/feature_gate_config.dart';
import '../../domain/entities/reminder.dart';

class ReminderMapper {
  const ReminderMapper._();

  static Map<String, dynamic> toRow(Reminder r) {
    return {
      // Omit id when 0 — let SQLite AUTOINCREMENT assign it on INSERT.
      if (r.id != 0) 'id': r.id,
      'subject': r.title,
      'scheduled_at': r.scheduledAt.millisecondsSinceEpoch,
      'category_id': r.categoryId,
      'dialect_code': r.dialectCode,
      'is_completed': r.isCompleted ? 1 : 0,
      'snoozed_until': r.snoozedUntil?.millisecondsSinceEpoch,
      'created_at': r.createdAt.millisecondsSinceEpoch,
      'updated_at': r.updatedAt.millisecondsSinceEpoch,
    };
  }

  static Reminder fromRow(Map<String, dynamic> row) {
    return Reminder(
      id: row['id'] as int,
      title: row['subject'] as String,
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(
        row['scheduled_at'] as int,
      ),
      recurrence: RecurrenceType.none, // joined from reminder_recurrences
      categoryId: row['category_id'] as int?,
      dialectCode: row['dialect_code'] as String? ?? 'ar-AE',
      isCompleted: (row['is_completed'] as int) == 1,
      snoozedUntil: row['snoozed_until'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['snoozed_until'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at'] as int,
      ),
    );
  }
}
