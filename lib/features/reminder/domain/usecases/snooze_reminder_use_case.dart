// lib/features/reminder/domain/usecases/snooze_reminder_use_case.dart
//
// Sprint 3.6 — F-N06: snooze a reminder by a chosen duration.
// No dartz — returns a plain result type matching this project's patterns.

import 'package:flutter/foundation.dart';
import 'package:tazakar/features/notification/data/datasources/local/notification_audit_dao.dart';
import 'package:tazakar/features/notification/domain/entities/notification_audit_log.dart';
import 'package:tazakar/core/services/notification_service.dart';
import 'package:tazakar/infrastructure/database/database_helper.dart';

class SnoozeParams {
  final int reminderId;
  final Duration duration;

  const SnoozeParams({required this.reminderId, required this.duration});
}

class SnoozeResult {
  final bool success;
  final String? errorMessage;
  final int rowsAffected;

  const SnoozeResult.ok(this.rowsAffected)
      : success = true,
        errorMessage = null;

  const SnoozeResult.error(this.errorMessage)
      : success = false,
        rowsAffected = 0;
}

class SnoozeReminderUseCase {
  final NotificationService _notificationService;
  final NotificationAuditDao _auditDao;

  const SnoozeReminderUseCase({
    required NotificationService notificationService,
    required NotificationAuditDao auditDao,
  })  : _notificationService = notificationService,
        _auditDao = auditDao;

  Future<SnoozeResult> call(SnoozeParams params) async {
    try {
      final db = await DatabaseHelper.database;

      // 1. Verify reminder exists and is not deleted
      final rows = await db.query(
        'reminders',
        where: 'id = ? AND is_completed = 0',
        whereArgs: [params.reminderId],
        limit: 1,
      );

      if (rows.isEmpty) {
        return const SnoozeResult.error('Reminder not found or already completed');
      }

      final reminder = rows.first;
      final title = reminder['subject'] as String? ?? 'تذكر';

      // 2. Cancel existing notification
      await _notificationService.cancelAll();

      // 3. Update snoozed_until in DB
      final newTime = DateTime.now().add(params.duration);
      final now = DateTime.now().millisecondsSinceEpoch;
      final rowsAffected = await db.update(
        'reminders',
        {
          'snoozed_until': newTime.millisecondsSinceEpoch,
          'scheduled_at': newTime.millisecondsSinceEpoch,
          'updated_at': now,
        },
        where: 'id = ? AND is_completed = 0',
        whereArgs: [params.reminderId],
      );

      // 4. Reschedule notification
      await _notificationService.scheduleNotificationOnly(
        reminderId: params.reminderId,
        title: title,
        body: 'تذكير مؤجل',
        scheduledAt: newTime,
      );

      // 5. Write audit row
      await _auditDao.insert(NotificationAuditLog(
        reminderId: params.reminderId,
        event: NotificationEvent.snoozed,
        occurredAt: DateTime.now(),
        meta: '{"duration_minutes":${params.duration.inMinutes}}',
      ));

      debugPrint('[SnoozeUseCase] Reminder #${params.reminderId} snoozed ${params.duration.inMinutes}min');
      return SnoozeResult.ok(rowsAffected);
    } catch (e) {
      debugPrint('[SnoozeUseCase] Error: $e');
      return SnoozeResult.error(e.toString());
    }
  }
}
