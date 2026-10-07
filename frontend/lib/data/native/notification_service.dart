import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/routine_item.dart';
import 'background_notification_handler.dart';
import 'notification_constants.dart';
import 'notification_details_builder.dart';

class NativeNotificationService {
  static const habitChannelId = NotificationConstants.habitChannelId;
  static const habitChannelName = NotificationConstants.habitChannelName;
  static const windowChannelId = NotificationConstants.windowChannelId;
  static const windowChannelName = NotificationConstants.windowChannelName;

  static const actionDone = NotificationConstants.actionDone;
  static const actionSnooze = NotificationConstants.actionSnooze;
  static const actionSkip = NotificationConstants.actionSkip;

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

  static String get currentLocalTimezoneName => tz.local.name;

  static void configureLocalTimezone(String? timeZoneName) {
    NotificationDetailsBuilder.configureLocalTimezone(timeZoneName);
  }

  static Future<void> initialize() async {
    await NotificationDetailsBuilder.syncDeviceTimezone();
    try {
      await plugin.initialize(
        settings: NotificationDetailsBuilder.buildInitSettings(),
        onDidReceiveNotificationResponse: notificationTapBackground,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      final androidPlugin = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  static Future<void> scheduleHabitReminder({
    required String routineId,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required int snoozeMinutes,
    DateTimeComponents? matchDateTimeComponents = DateTimeComponents.time,
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
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails:
            NotificationDetailsBuilder.buildHabitDetails(snoozeMinutes),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
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
    await cancelHabitReminder(routineId);
    await scheduleHabitReminder(
      routineId: routineId,
      title: title,
      body: 'Snoozed reminder ($title)',
      scheduledDate: targetTime,
      snoozeMinutes: snoozeMinutes,
      matchDateTimeComponents: null,
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
      await plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: NotificationDetailsBuilder.buildWindowDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {}
  }

  static Future<void> cancelHabitReminder(String routineId) async {
    try {
      await plugin.cancel(id: getNotificationIdForRoutine(routineId));
    } catch (_) {}
  }

  static Future<void> cancelWindowNudge(TimeWindow window) async {
    try {
      await plugin.cancel(id: getNotificationIdForWindow(window));
    } catch (_) {}
  }

  static Future<void> cancelOrphanReminders(Set<int> validIds) async {
    try {
      final pending = await plugin.pendingNotificationRequests();
      for (final req in pending) {
        if (!validIds.contains(req.id)) {
          await plugin.cancel(id: req.id);
        }
      }
    } catch (_) {}
  }
}
