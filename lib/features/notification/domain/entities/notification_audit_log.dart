// lib/features/notification/domain/entities/notification_audit_log.dart
//
// Sprint 3.6 — F-N07/F-N08: notification audit trail.

import 'package:equatable/equatable.dart';

enum NotificationEvent {
  scheduled,
  delivered,
  dismissed,
  snoozed,
  cancelled,
  rescheduled;

  String get value => name;

  static NotificationEvent fromString(String s) =>
      NotificationEvent.values.firstWhere((e) => e.value == s);
}

class NotificationAuditLog extends Equatable {
  final int id;               // AUTOINCREMENT
  final int reminderId;
  final NotificationEvent event;
  final DateTime occurredAt;
  final String? meta;         // e.g. snooze duration as JSON

  const NotificationAuditLog({
    this.id = 0,
    required this.reminderId,
    required this.event,
    required this.occurredAt,
    this.meta,
  });

  @override
  List<Object?> get props => [id, reminderId, event, occurredAt, meta];
}
