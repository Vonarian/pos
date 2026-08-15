import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../local/database.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  final actionId = response.actionId;
  final payload = response.payload;
  if (payload == null || actionId == null) return;

  Map<String, dynamic> data;
  try {
    data = jsonDecode(payload) as Map<String, dynamic>;
  } catch (_) {
    return;
  }

  final routineId = data['routineId'] as String?;
  if (routineId == null) return;

  final db = AppDatabase();
  try {
    await _handleBackgroundAction(db, actionId, routineId, data);
  } finally {
    await db.close();
  }
}

Future<void> _handleBackgroundAction(
  AppDatabase db,
  String actionId,
  String routineId,
  Map<String, dynamic> data,
) async {
  if (actionId == NativeNotificationService.actionDone) {
    await db.routineDao.updateStatus(routineId, 'COMPLETED', DateTime.now());
  } else if (actionId == NativeNotificationService.actionSkip) {
    await db.routineDao.updateStatus(routineId, 'SKIPPED', null);
  } else if (actionId == NativeNotificationService.actionSnooze) {
    final snoozeMins = data['snoozeMinutes'] as int? ?? 15;
    final title = data['title'] as String? ?? 'Habit Reminder';
    final targetTime = DateTime.now().add(Duration(minutes: snoozeMins));
    await NativeNotificationService.scheduleSnooze(
      routineId: routineId,
      title: title,
      targetTime: targetTime,
      snoozeMinutes: snoozeMins,
    );
  }
}
