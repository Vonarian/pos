import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/data/local/database.dart';
import 'package:pos_frontend/data/repositories/offline_routine_spawner.dart';
import 'package:pos_frontend/domain/models/routine_item.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('OfflineRoutineSpawner', () {
    test('does not create templates or spawn one-time reminders for subsequent days', () async {
      final now = DateTime.now();
      const today = '2026-08-21';
      const tomorrow = '2026-08-22';

      // Insert a one-time reminder for tonight
      await db.routineDao.upsertRoutine(
        RoutineItemsTableCompanion.insert(
          id: 'one_time_reminder_1',
          title: 'Buy groceries tonight',
          category: 'HABIT',
          timeWindow: TimeWindow.evening.value,
          scheduledDate: today,
          status: const Value('PENDING'),
          metadataJson: Value(
            jsonEncode({
              'reminder': {
                'enabled': true,
                'is_recurring': false,
                'time': '20:00',
                'days_of_week': [],
              },
            }),
          ),
          updatedAt: now,
          createdAt: now,
          isSynced: const Value(false),
        ),
      );

      // Trigger spawner for today then tomorrow
      await OfflineRoutineSpawner.ensureSpawnedForDate(db, today);
      await OfflineRoutineSpawner.ensureSpawnedForDate(db, tomorrow);

      final templates = await db.routineTemplateDao.getActiveTemplates();
      expect(templates, isEmpty, reason: 'One-time reminders should not create templates');

      final tomorrowRoutines = await db.routineDao.getRoutinesForDate(tomorrow);
      expect(tomorrowRoutines, isEmpty, reason: 'One-time reminders should not spawn for tomorrow');
    });

    test('creates template and spawns recurring habits for subsequent days', () async {
      final now = DateTime.now();
      const today = '2026-08-21';
      const tomorrow = '2026-08-22'; // Saturday (day 6)

      await db.routineDao.upsertRoutine(
        RoutineItemsTableCompanion.insert(
          id: 'recurring_habit_1',
          title: 'Creatine 5g',
          category: 'MEDS',
          timeWindow: TimeWindow.morning.value,
          scheduledDate: today,
          status: const Value('PENDING'),
          metadataJson: Value(
            jsonEncode({
              'reminder': {
                'enabled': true,
                'is_recurring': true,
                'time': '08:00',
                'days_of_week': [1, 2, 3, 4, 5, 6, 7],
              },
            }),
          ),
          updatedAt: now,
          createdAt: now,
          isSynced: const Value(false),
        ),
      );

      await OfflineRoutineSpawner.ensureSpawnedForDate(db, today);
      await OfflineRoutineSpawner.ensureSpawnedForDate(db, tomorrow);

      final templates = await db.routineTemplateDao.getActiveTemplates();
      expect(templates.length, 1);
      expect(templates.first.title, 'Creatine 5g');

      final tomorrowRoutines = await db.routineDao.getRoutinesForDate(tomorrow);
      expect(tomorrowRoutines.length, 1);
      expect(tomorrowRoutines.first.title, 'Creatine 5g');
    });

    test('does not resurrect deactivated template when legacy routines exist', () async {
      final now = DateTime.now();
      const today = '2026-08-21';
      const tplId = 'tpl_deactivated_habit';

      await db.routineTemplateDao.upsertTemplate(
        RoutineTemplatesTableCompanion.insert(
          id: tplId,
          title: 'Removed Running Habit',
          category: 'HABIT',
          timeWindow: TimeWindow.morning.value,
          daysOfWeekJson: const Value('[1,2,3,4,5,6,7]'),
          isActive: const Value(false),
          updatedAt: now,
          createdAt: now,
        ),
      );

      await db.routineDao.upsertRoutine(
        RoutineItemsTableCompanion.insert(
          id: 'old_running_item',
          templateId: const Value(tplId),
          title: 'Removed Running Habit',
          category: 'HABIT',
          timeWindow: TimeWindow.morning.value,
          scheduledDate: '2026-08-20',
          status: const Value('COMPLETED'),
          metadataJson: Value(
            jsonEncode({
              'reminder': {
                'enabled': true,
                'is_recurring': true,
                'time': '07:00',
              },
            }),
          ),
          updatedAt: now,
          createdAt: now,
        ),
      );

      await OfflineRoutineSpawner.ensureSpawnedForDate(db, today);

      final activeTemplates = await db.routineTemplateDao.getActiveTemplates();
      expect(activeTemplates, isEmpty, reason: 'Deactivated template must not be resurrected');

      final todayRoutines = await db.routineDao.getRoutinesForDate(today);
      expect(todayRoutines, isEmpty, reason: 'Removed habit must not spawn routines');
    });
  });
}
