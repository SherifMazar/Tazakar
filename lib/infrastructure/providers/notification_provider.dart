import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tazakar/features/notification/data/datasources/local/notification_audit_dao.dart';
import 'package:tazakar/core/services/notification_service.dart';
import 'package:tazakar/infrastructure/database/database_service.dart';

/// Riverpod provider for [NotificationService].
/// Mirrors the DatabaseService provider pattern (DEC-24).
///
/// Usage:
///   final notifications = ref.read(notificationServiceProvider);
///   await notifications.scheduleReminder(...);
final notificationAuditDaoProvider = Provider<NotificationAuditDao>((ref) {
  return NotificationAuditDao();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    plugin: FlutterLocalNotificationsPlugin(),
    auditDao: ref.read(notificationAuditDaoProvider),
  );
});

/// Async initialisation provider — call once from app bootstrap (main.dart).
/// Ensures NotificationService.init() completes before UI renders.
final notificationInitProvider = FutureProvider<void>((ref) async {
  final service = ref.read(notificationServiceProvider);
  await service.init();
});

/// Reschedule provider — call on cold start after DB is ready.
/// Depends on databaseProvider being initialised first.
final rescheduleOnBootProvider = FutureProvider<void>((ref) async {
  final service = ref.read(notificationServiceProvider);
  final dbAsync = ref.watch(databaseServiceProvider);
  final db = dbAsync.valueOrNull;
  if (db == null) return;
  await service.rescheduleAll(db);
});
