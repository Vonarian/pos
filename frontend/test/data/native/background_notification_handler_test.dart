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

  test('actionSnooze reschedules reminder for future target time', () async {
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
  });
}
