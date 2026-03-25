// lib/features/notification/domain/usecases/get_notification_audit_log_use_case.dart
//
// Sprint 3.6 — F-N08: retrieve audit history for a reminder.

import 'package:flutter/foundation.dart';
import '../entities/notification_audit_log.dart';
import '../../data/datasources/local/notification_audit_dao.dart';

class GetNotificationAuditLogUseCase {
  final NotificationAuditDao _auditDao;

  const GetNotificationAuditLogUseCase({required NotificationAuditDao auditDao})
      : _auditDao = auditDao;

  Future<List<NotificationAuditLog>> forReminder(int reminderId) async {
    try {
      return await _auditDao.forReminder(reminderId);
    } catch (e) {
      debugPrint('[AuditLogUseCase] Error: $e');
      return [];
    }
  }

  Future<List<NotificationAuditLog>> recent({int limit = 50}) async {
    try {
      return await _auditDao.recentEvents(limit: limit);
    } catch (e) {
      debugPrint('[AuditLogUseCase] Error: $e');
      return [];
    }
  }
}
