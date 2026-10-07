import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/data/local/database.dart';
import 'package:pos_frontend/data/native/background_notification_handler.dart';
import 'package:pos_frontend/data/native/notification_constants.dart';
import 'package:pos_frontend/data/native/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedRoutine(String id, String status) async {
    final now = DateTime.now();
    await db.routineDao.upsertRoutine(
      RoutineItemsTableCompanion.insert(
        id: id,
        title: 'Morning Meditation',
        category: 'HABIT',
        timeWindow: 'MORNING',
        scheduledDate: '2026-08-15',
        status: Value(status),
        updatedAt: now,
        createdAt: now,
      ),
    );
  }

  test('actionDone updates status to COMPLETED and cancels notification', () async {
    await seedRoutine('routine-done-1', 'PENDING');

    final payload = NativeNotificationService.buildPayload(
      routineId: 'routine-done-1',
      title: 'Morning Meditation',
      snoozeMinutes: 10,
    );

    final response = NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
      actionId: NotificationConstants.actionDone,
      payload: payload,
    );

    await handleBackgroundNotificationResponse(response, db: db);

    final item = await db.routineDao.getRoutineById('routine-done-1');
    expect(item?.status, 'COMPLETED');
    expect(item?.completedAt, isNotNull);
  });

  test('actionSkip updates status to SKIPPED and cancels notification', () async {
    await seedRoutine('routine-skip-1', 'PENDING');

    final payload = NativeNotificationService.buildPayload(
      routineId: 'routine-skip-1',
      title: 'Morning Meditation',
      snoozeMinutes: 10,
    );

    final response = NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
      actionId: NotificationConstants.actionSkip,
      payload: payload,
    );

    await handleBackgroundNotificationResponse(response, db: db);

    final item = await db.routineDao.getRoutineById('routine-skip-1');
    expect(item?.status, 'SKIPPED');
  });

  test('actionSnooze reschedules reminder and persists lastSnoozedUntil in metadata', () async {
    await seedRoutine('routine-snooze-1', 'PENDING');

    final payload = NativeNotificationService.buildPayload(
      routineId: 'routine-snooze-1',
      title: 'Morning Meditation',
      snoozeMinutes: 15,
    );

    final response = NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
      actionId: NotificationConstants.actionSnooze,
      payload: payload,
    );

    await handleBackgroundNotificationResponse(response, db: db);

    final item = await db.routineDao.getRoutineById('routine-snooze-1');
    expect(item?.status, 'PENDING');
    expect(item?.metadataJson, contains('last_snoozed_until'));
  });

  test('actionDone on prior day recurring notification spawns and completes today routine', () async {
    final now = DateTime.now();
    final todayStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await db.routineTemplateDao.upsertTemplate(
      RoutineTemplatesTableCompanion.insert(
        id: 'tpl_med_1',
        title: 'Daily Vitamin D',
        category: 'MEDS',
        timeWindow: 'MORNING',
        daysOfWeekJson: const Value('[1,2,3,4,5,6,7]'),
        metadataJson: const Value(
          '{"reminder":{"enabled":true,"is_recurring":true,"time":"08:00"}}',
        ),
        isActive: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.routineDao.upsertRoutine(
      RoutineItemsTableCompanion.insert(
        id: 'tpl_med_1_2026-08-14',
        templateId: const Value('tpl_med_1'),
        title: 'Daily Vitamin D',
        category: 'MEDS',
        timeWindow: 'MORNING',
        scheduledDate: '2026-08-14',
        status: const Value('COMPLETED'),
        metadataJson: const Value(
          '{"reminder":{"enabled":true,"is_recurring":true,"time":"08:00"}}',
        ),
        updatedAt: now,
        createdAt: now,
      ),
    );

    final payload = NativeNotificationService.buildPayload(
      routineId: 'tpl_med_1_2026-08-14',
      title: 'Daily Vitamin D',
      snoozeMinutes: 15,
    );

    final response = NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
      actionId: NotificationConstants.actionDone,
      payload: payload,
    );

    await handleBackgroundNotificationResponse(response, db: db);

    final todayItem = await db.routineDao.getRoutineById('tpl_med_1_$todayStr');
    expect(todayItem, isNotNull);
    expect(todayItem?.status, 'COMPLETED');
  });
}
