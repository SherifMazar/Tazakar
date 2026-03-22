import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import 'database_provider.dart';

/// Riverpod provider for [NotificationService].
/// Mirrors the DatabaseService provider pattern (DEC-24).
///
/// Usage:
///   final notifications = ref.read(notificationServiceProvider);
///   await notifications.scheduleReminder(...);
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
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
  final db = await ref.watch(databaseProvider.future);
  await service.rescheduleAll(db);
});
