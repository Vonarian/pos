import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
}
