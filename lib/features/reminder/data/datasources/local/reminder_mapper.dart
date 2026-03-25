// lib/features/reminder/data/datasources/local/reminder_mapper.dart
//
// DEC-30: id is now INTEGER (int) not TEXT (String).

import '../../../../domain/entities/reminder.dart';

class ReminderMapper {
  // DB row → domain entity
  static Reminder fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int,                              // INTEGER PK
      title: map['title'] as String,
      notes: map['notes'] as String?,
      remindAt: DateTime.fromMillisecondsSinceEpoch(
        map['remind_at'] as int,
      ),
      recurrence: RecurrenceType.fromString(
        map['recurrence'] as String,
      ),
      categoryId: map['category_id'] as int?,
      isCompleted: (map['is_completed'] as int) == 1,
      isDeleted: (map['is_deleted'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updated_at'] as int,
      ),
    );
  }

  // Domain entity → DB row (omit id so AUTOINCREMENT applies on insert)
  static Map<String, dynamic> toMap(Reminder reminder) {
    final map = <String, dynamic>{
      'title': reminder.title,
      'notes': reminder.notes,
      'remind_at': reminder.remindAt.millisecondsSinceEpoch,
      'recurrence': reminder.recurrence.value,
      'category_id': reminder.categoryId,
      'is_completed': reminder.isCompleted ? 1 : 0,
      'is_deleted': reminder.isDeleted ? 1 : 0,
      'created_at': reminder.createdAt.millisecondsSinceEpoch,
      'updated_at': reminder.updatedAt.millisecondsSinceEpoch,
    };
    // Only include id on updates (not inserts)
    if (reminder.id != 0) map['id'] = reminder.id;
    return map;
  }
}
