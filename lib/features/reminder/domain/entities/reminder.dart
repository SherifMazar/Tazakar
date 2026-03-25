import 'package:equatable/equatable.dart';
import 'package:tazakar/core/services/feature_gate/feature_gate_config.dart';

/// Core domain entity. No Flutter or DB imports — pure Dart.
class Reminder extends Equatable {
  const Reminder({
    this.id,
    required this.title,
    required this.scheduledAt,
    required this.recurrenceType,
    required this.categoryId,
    required this.isCompleted,
    required this.createdAt,
    this.updatedAt,
    this.notes,
    this.snoozedUntil,
    this.dialectCode = 'ar-AE',
  });

  /// Null until persisted.
  final String? id;
  final String title;
  final DateTime scheduledAt;
  final RecurrenceType recurrenceType;
  final int categoryId;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final DateTime? snoozedUntil;
  final String dialectCode;

  Reminder copyWith({
    String? id,
    String? title,
    DateTime? scheduledAt,
    RecurrenceType? recurrenceType,
    int? categoryId,
    bool? isCompleted,
    DateTime? updatedAt,
    String? notes,
    DateTime? snoozedUntil,
    String? dialectCode,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      categoryId: categoryId ?? this.categoryId,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      dialectCode: dialectCode ?? this.dialectCode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        scheduledAt,
        recurrenceType,
        categoryId,
        isCompleted,
        createdAt,
        updatedAt,
        notes,
        snoozedUntil,
        dialectCode,
      ];
}
