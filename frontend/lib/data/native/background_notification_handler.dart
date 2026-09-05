import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../local/database.dart';
import 'notification_constants.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  await handleBackgroundNotificationResponse(response);
}

Future<void> handleBackgroundNotificationResponse(
  NotificationResponse response, {
  AppDatabase? db,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    tz.initializeTimeZones();
  } catch (_) {}

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

  final database = db ?? AppDatabase();
  try {
    await _handleBackgroundAction(database, actionId, routineId, data);
  } finally {
    if (db == null) {
      await database.close();
    }
  }
}

Future<void> _handleBackgroundAction(
  AppDatabase db,
  String actionId,
  String routineId,
  Map<String, dynamic> data,
) async {
  if (actionId == NotificationConstants.actionDone) {
    await db.routineDao.updateStatus(routineId, 'COMPLETED', DateTime.now());
    await NativeNotificationService.cancelHabitReminder(routineId);
  } else if (actionId == NotificationConstants.actionSkip) {
    await db.routineDao.updateStatus(routineId, 'SKIPPED', null);
    await NativeNotificationService.cancelHabitReminder(routineId);
  } else if (actionId == NotificationConstants.actionSnooze) {
    await NativeNotificationService.cancelHabitReminder(routineId);
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
