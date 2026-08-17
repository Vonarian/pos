import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/routine_item.dart';
import 'background_notification_handler.dart';

class NativeNotificationService {
  static const habitChannelId = 'pos_habit_reminders';
  static const habitChannelName = 'Habit & Medication Reminders';
  static const windowChannelId = 'pos_window_nudges';
  static const windowChannelName = 'Time Window Closing Alerts';

  static const actionDone = 'ACTION_DONE';
  static const actionSnooze = 'ACTION_SNOOZE';
  static const actionSkip = 'ACTION_SKIP';

  static FlutterLocalNotificationsPlugin? _pluginInstance;

  static FlutterLocalNotificationsPlugin get plugin {
    _pluginInstance ??= FlutterLocalNotificationsPlugin();
    return _pluginInstance!;
  }

  static void setPluginForTesting(FlutterLocalNotificationsPlugin testPlugin) {
    _pluginInstance = testPlugin;
  }

  static int getNotificationIdForRoutine(String routineId) {
    return routineId.hashCode & 0x7FFFFFFF;
  }

  static int getNotificationIdForWindow(TimeWindow window) {
    return 0x70000000 + window.index;
  }

  static String buildPayload({
    required String routineId,
    required String title,
    required int snoozeMinutes,
  }) {
    return jsonEncode({
      'routineId': routineId,
      'title': title,
      'snoozeMinutes': snoozeMinutes,
    });
  }

  static Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
    } catch (_) {}

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open POS',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    try {
      await plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          notificationTapBackground(response);
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
    } catch (_) {}
  }

  static NotificationDetails _buildHabitDetails(int snoozeMinutes) {
    final actions = [
      const AndroidNotificationAction(
        actionDone,
        'Mark Done',
        showsUserInterface: false,
      ),
      AndroidNotificationAction(
        actionSnooze,
        'Snooze (${snoozeMinutes}m)',
        showsUserInterface: false,
      ),
      const AndroidNotificationAction(
        actionSkip,
        'Skip',
        showsUserInterface: false,
      ),
    ];

    final android = AndroidNotificationDetails(
      habitChannelId,
      habitChannelName,
      importance: Importance.max,
      priority: Priority.high,
      actions: actions,
      category: AndroidNotificationCategory.reminder,
    );

    return NotificationDetails(android: android);
  }

  static Future<void> scheduleHabitReminder({
    required String routineId,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required int snoozeMinutes,
  }) async {
    try {
      final id = getNotificationIdForRoutine(routineId);
      final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
      final payload = buildPayload(
        routineId: routineId,
        title: title,
        snoozeMinutes: snoozeMinutes,
      );

      await plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        _buildHabitDetails(snoozeMinutes),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (_) {}
  }

  static Future<void> scheduleSnooze({
    required String routineId,
    required String title,
    required DateTime targetTime,
    required int snoozeMinutes,
  }) async {
    await scheduleHabitReminder(
      routineId: routineId,
      title: title,
      body: 'Snoozed reminder ($title)',
      scheduledDate: targetTime,
      snoozeMinutes: snoozeMinutes,
    );
  }

  static Future<void> scheduleWindowNudge({
    required TimeWindow window,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      final id = getNotificationIdForWindow(window);
      final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
      const android = AndroidNotificationDetails(
        windowChannelId,
        windowChannelName,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      );

      await plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        const NotificationDetails(android: android),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  static Future<void> cancelHabitReminder(String routineId) async {
    try {
      await plugin.cancel(getNotificationIdForRoutine(routineId));
    } catch (_) {}
  }

  static Future<void> cancelWindowNudge(TimeWindow window) async {
    try {
      await plugin.cancel(getNotificationIdForWindow(window));
    } catch (_) {}
  }
}
