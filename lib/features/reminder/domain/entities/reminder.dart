// lib/features/reminder/domain/entities/reminder.dart
//
// DEC-30: id is INTEGER PRIMARY KEY AUTOINCREMENT — sentinel 0 = unsaved.
// Schema v2 columns: subject, category_id, scheduled_at, dialect_code,
//                    is_completed, snoozed_until, created_at, updated_at.
// Notes and isDeleted removed — not in schema v2.

import 'package:equatable/equatable.dart';
import '../../../../core/services/feature_gate/feature_gate_config.dart';

class Reminder extends Equatable {
  /// 0 = unsaved (not yet inserted). SQLite assigns the real id on insert.
  final int id;
  final String title;
  final DateTime scheduledAt;
  final RecurrenceType recurrence;
  final int? categoryId;
  final String dialectCode;
  final bool isCompleted;
  final DateTime? snoozedUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    this.id = 0,
    required this.title,
    required this.scheduledAt,
    this.recurrence = RecurrenceType.none,
    this.categoryId,
    this.dialectCode = 'ar-AE',
    this.isCompleted = false,
    this.snoozedUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  Reminder copyWith({
    int? id,
    String? title,
    DateTime? scheduledAt,
    RecurrenceType? recurrence,
    int? categoryId,
    String? dialectCode,
    bool? isCompleted,
    DateTime? snoozedUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      recurrence: recurrence ?? this.recurrence,
      categoryId: categoryId ?? this.categoryId,
      dialectCode: dialectCode ?? this.dialectCode,
      isCompleted: isCompleted ?? this.isCompleted,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        scheduledAt,
        recurrence,
        categoryId,
        dialectCode,
        isCompleted,
        snoozedUntil,
        createdAt,
        updatedAt,
      ];
}
