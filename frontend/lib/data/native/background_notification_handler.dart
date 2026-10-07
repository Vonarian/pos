import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:drift/drift.dart';

import '../local/database.dart';
import '../repositories/offline_routine_mapper.dart';
import '../repositories/offline_routine_spawner.dart';
import '../services/reminder_scheduler_service.dart';
import 'notification_constants.dart';
import 'notification_details_builder.dart';
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
  NotificationDetailsBuilder.configureLocalTimezone(null);

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

String _todayStr(DateTime now) =>
    '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

Future<RoutineItemsTableData?> _resolveTargetRoutine(
  AppDatabase db,
  String routineId,
  String todayStr,
) async {
  await OfflineRoutineSpawner.ensureSpawnedForDate(db, todayStr);
  final existing = await db.routineDao.getRoutineById(routineId);
  if (existing == null || existing.scheduledDate == todayStr) {
    return existing;
  }
  final tplId = existing.templateId ?? 'tpl_$routineId';
  final todayRows = await db.routineDao.getRoutinesForDate(todayStr);
  for (final r in todayRows) {
    if (r.templateId == tplId) return r;
  }
  return existing;
}

Future<void> _rescheduleIfRecurring(
  AppDatabase db,
  String targetId,
  DateTime now,
) async {
  final updatedRow = await db.routineDao.getRoutineById(targetId);
  if (updatedRow == null) return;
  final domain = OfflineRoutineMapper.mapRowToDomain(updatedRow);
  if (!domain.isRecurring) return;
  final nextTrigger = ReminderSchedulerService.calculateReminderTrigger(
    item: domain,
    now: now,
  );
  if (nextTrigger == null) return;
  final config = domain.reminderConfig;
  await NativeNotificationService.scheduleHabitReminder(
    routineId: domain.id,
    title: domain.title,
    body: 'Scheduled reminder for ${domain.title}',
    scheduledDate: nextTrigger,
    snoozeMinutes: config?.snoozeMinutes ?? 15,
    matchDateTimeComponents: (config?.isDaily ?? true)
        ? DateTimeComponents.time
        : DateTimeComponents.dayOfWeekAndTime,
  );
}

Future<void> _persistSnoozeUntil(
  AppDatabase db,
  RoutineItemsTableData? target,
  DateTime targetTime,
) async {
  if (target == null) return;
  Map<String, dynamic> meta = {};
  try {
    meta = jsonDecode(target.metadataJson) as Map<String, dynamic>;
  } catch (_) {}
  final reminder = Map<String, dynamic>.from(
    (meta['reminder'] as Map<String, dynamic>?) ?? <String, dynamic>{},
  );
  reminder['last_snoozed_until'] = targetTime.toIso8601String();
  meta['reminder'] = reminder;
  await db.routineDao.upsertRoutine(
    target.toCompanion(true).copyWith(
      metadataJson: Value(jsonEncode(meta)),
      updatedAt: Value(DateTime.now()),
    ),
  );
}

Future<void> _handleBackgroundAction(
  AppDatabase db,
  String actionId,
  String routineId,
  Map<String, dynamic> data,
) async {
  final now = DateTime.now();
  final target = await _resolveTargetRoutine(db, routineId, _todayStr(now));
  final targetId = target?.id ?? routineId;

  if (actionId == NotificationConstants.actionDone) {
    await db.routineDao.updateStatus(targetId, 'COMPLETED', now);
    await NativeNotificationService.cancelHabitReminder(routineId);
    await NativeNotificationService.cancelHabitReminder(targetId);
    await _rescheduleIfRecurring(db, targetId, now);
  } else if (actionId == NotificationConstants.actionSkip) {
    await db.routineDao.updateStatus(targetId, 'SKIPPED', null);
    await NativeNotificationService.cancelHabitReminder(routineId);
    await NativeNotificationService.cancelHabitReminder(targetId);
    await _rescheduleIfRecurring(db, targetId, now);
  } else if (actionId == NotificationConstants.actionSnooze) {
    await NativeNotificationService.cancelHabitReminder(routineId);
    await NativeNotificationService.cancelHabitReminder(targetId);
    final snoozeMins = data['snoozeMinutes'] as int? ?? 15;
    final title = data['title'] as String? ?? 'Habit Reminder';
    final targetTime = now.add(Duration(minutes: snoozeMins));
    await _persistSnoozeUntil(db, target, targetTime);
    await NativeNotificationService.scheduleSnooze(
      routineId: targetId,
      title: title,
      targetTime: targetTime,
      snoozeMinutes: snoozeMins,
    );
  }
}
