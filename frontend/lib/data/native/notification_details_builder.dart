import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_constants.dart';

class NotificationDetailsBuilder {
  static NotificationDetails buildHabitDetails(int snoozeMinutes) {
    final actions = [
      const AndroidNotificationAction(
        NotificationConstants.actionDone,
        'Mark Done',
        showsUserInterface: false,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        NotificationConstants.actionSnooze,
        'Snooze (${snoozeMinutes}m)',
        showsUserInterface: false,
        cancelNotification: true,
      ),
      const AndroidNotificationAction(
        NotificationConstants.actionSkip,
        'Skip',
        showsUserInterface: false,
        cancelNotification: true,
      ),
    ];

    final android = AndroidNotificationDetails(
      NotificationConstants.habitChannelId,
      NotificationConstants.habitChannelName,
      importance: Importance.max,
      priority: Priority.high,
      actions: actions,
      category: AndroidNotificationCategory.reminder,
    );

    return NotificationDetails(android: android);
  }

  static NotificationDetails buildWindowDetails() {
    const android = AndroidNotificationDetails(
      NotificationConstants.windowChannelId,
      NotificationConstants.windowChannelName,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    );
    return const NotificationDetails(android: android);
  }

  static InitializationSettings buildInitSettings() {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const linux = LinuxInitializationSettings(defaultActionName: 'Open POS');
    return const InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
    );
  }

  static void configureLocalTimezone(String? timeZoneName) {
    try {
      tz.initializeTimeZones();
    } catch (_) {}
    if (timeZoneName != null &&
        tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      return;
    }
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (loc.timeZone(nowMs).offset == now.timeZoneOffset) {
        tz.setLocalLocation(loc);
        return;
      }
    }
  }

  static Future<void> syncDeviceTimezone() async {
    String? tzName;
    try {
      const channel = MethodChannel('com.pos.app/health');
      tzName = await channel.invokeMethod<String>('getLocalTimezone');
    } catch (_) {}
    configureLocalTimezone(tzName);
  }
}
