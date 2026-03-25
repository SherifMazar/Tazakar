// lib/features/reminder/domain/entities/reminder.dart
//
// DEC-30: id changed from String (UUID) to int (AUTOINCREMENT).

import 'package:equatable/equatable.dart';
import '../../../../core/services/feature_gate/feature_gate_config.dart';

class Reminder extends Equatable {
  final int id;           // 0 = unsaved (new)
  final String title;
  final String? notes;
  final DateTime remindAt;
  final RecurrenceType recurrence;
  final int? categoryId;
  final bool isCompleted;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    this.id = 0,
    required this.title,
    this.notes,
    required this.remindAt,
    this.recurrence = RecurrenceType.none,
    this.categoryId,
    this.isCompleted = false,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Reminder copyWith({
    int? id,
    String? title,
    String? notes,
    DateTime? remindAt,
    RecurrenceType? recurrence,
    int? categoryId,
    bool? isCompleted,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      remindAt: remindAt ?? this.remindAt,
      recurrence: recurrence ?? this.recurrence,
      categoryId: categoryId ?? this.categoryId,
      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        notes,
        remindAt,
        recurrence,
        categoryId,
        isCompleted,
        isDeleted,
        createdAt,
        updatedAt,
      ];
}
