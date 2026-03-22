import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:tazakar/infrastructure/database/database_service.dart';

/// Fully local notification service — no FCM, no cloud (SC-01 / FR-P02).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _androidChannelId = 'tazakar_reminders';
  static const String _androidChannelName = 'Tazakar Reminders';
  static const String _androidChannelDesc =
      'Scheduled reminder notifications for Tazakar';

  bool _initialised = false;

  // ─────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────

  Future<void> init() async {
    if (_initialised) return;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _createAndroidChannel();

    if (defaultTargetPlatform == TargetPlatform.android) {
      await AndroidAlarmManager.initialize();
    }

    _initialised = true;
    debugPrint('[NotificationService] Initialised');
  }

  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ─────────────────────────────────────────────
  // SCHEDULE
  // ─────────────────────────────────────────────

  /// Schedules a local notification for a reminder and persists to DB.
  Future<void> scheduleReminder({
    required int reminderId,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required DatabaseService db,
  }) async {
    if (!_initialised) await init();

    await _zonedSchedule(
      reminderId: reminderId,
      title: title,
      body: body,
      scheduledAt: scheduledAt,
    );

    await _persistNotification(
      reminderId: reminderId,
      scheduledAt: scheduledAt,
      db: db,
    );

    debugPrint('[NotificationService] Scheduled #$reminderId at $scheduledAt');
  }

  /// Test-only: schedules a notification without persisting to DB.
  /// Used for AQ-03 Doze reliability verification.
  Future<void> scheduleNotificationOnly({
    required int reminderId,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    if (!_initialised) await init();

    await _zonedSchedule(
      reminderId: reminderId,
      title: title,
      body: body,
      scheduledAt: scheduledAt,
    );

    debugPrint('[NotificationService] Test scheduled #$reminderId at $scheduledAt');
  }

  Future<void> _zonedSchedule({
    required int reminderId,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'تذكر',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduled = _toTZDateTime(scheduledAt);

    await _plugin.zonedSchedule(
      reminderId,
      title,
      body,
      tzScheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ─────────────────────────────────────────────
  // CANCEL
  // ─────────────────────────────────────────────

  Future<void> cancelReminder(int reminderId, DatabaseService db) async {
    if (!_initialised) await init();
    await _plugin.cancel(reminderId);
    await _markCancelled(reminderId, db);
    debugPrint('[NotificationService] Cancelled #$reminderId');
  }

  Future<void> cancelAll() async {
    if (!_initialised) await init();
    await _plugin.cancelAll();
    debugPrint('[NotificationService] All notifications cancelled');
  }

  // ─────────────────────────────────────────────
  // RESCHEDULE ALL (cold start / reboot)
  // ─────────────────────────────────────────────

  Future<void> rescheduleAll(DatabaseService db) async {
    if (!_initialised) await init();

    final now = DateTime.now();

    final rows = await db.db.rawQuery('''
      SELECT id, title, body, trigger_at
      FROM reminders
      WHERE is_deleted = 0
        AND trigger_at > ?
      ORDER BY trigger_at ASC
    ''', [now.millisecondsSinceEpoch]);

    int count = 0;
    for (final row in rows) {
      final reminderId = row['id'] as String;
      final title = row['title'] as String? ?? 'تذكر';
      final body = row['body'] as String? ?? '';
      final triggerAt = DateTime.fromMillisecondsSinceEpoch(
        row['trigger_at'] as int,
      );

      await scheduleReminder(
        reminderId: int.tryParse(reminderId) ?? 0,
        title: title,
        body: body,
        scheduledAt: triggerAt,
        db: db,
      );
      count++;
    }

    debugPrint('[NotificationService] Rescheduled $count pending reminders');
  }

  // ─────────────────────────────────────────────
  // DB HELPERS
  // ─────────────────────────────────────────────

  Future<void> _persistNotification({
    required int reminderId,
    required DateTime scheduledAt,
    required DatabaseService db,
  }) async {
    await db.db.insert(
      'notifications',
      {
        'id': const Uuid().v4(),
        'reminder_id': reminderId.toString(),
        'scheduled_at': scheduledAt.millisecondsSinceEpoch,
        'status': 'scheduled',
        'delivered_at': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _markCancelled(int reminderId, DatabaseService db) async {
    await db.db.update(
      'notifications',
      {'status': 'cancelled'},
      where: 'reminder_id = ?',
      whereArgs: [reminderId.toString()],
    );
  }

  // ─────────────────────────────────────────────
  // TIMEZONE HELPER
  // ─────────────────────────────────────────────

  tz.TZDateTime _toTZDateTime(DateTime dateTime) {
    final location = tz.local;
    return tz.TZDateTime.from(dateTime, location);
  }

  // ─────────────────────────────────────────────
  // CALLBACKS
  // ─────────────────────────────────────────────

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('[NotificationService] Tapped notification id=${response.id}');
    // TODO(S3.3): Navigate to reminder detail screen via go_router
  }
}
