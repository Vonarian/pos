import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/data/local/database.dart';
import 'package:pos_frontend/data/repositories/offline_routine_repository.dart';
import 'package:pos_frontend/domain/models/routine_item.dart';

void main() {
  late AppDatabase db;
  late OfflineRoutineRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = OfflineRoutineRepository(db: db, apiClient: null);
  });

  tearDown(() async {
    await db.close();
  });

  test('offline repository create, complete, defer and retrieve', () async {
    final now = DateTime.now();
    final item = RoutineItem(
      id: 'item-repo-1',
      title: 'Morning Yoga',
      category: 'HABIT',
      timeWindow: TimeWindow.morning,
      scheduledDate: '2026-08-15',
      status: ItemStatus.pending,
      updatedAt: now,
      createdAt: now,
    );

    await repo.createRoutine(item);
    var routines = await repo.getRoutinesForDate('2026-08-15');
    expect(routines.length, 1);
    expect(routines.first.title, 'Morning Yoga');
    expect(routines.first.status, ItemStatus.pending);

    // Complete item
    await repo.completeRoutine('item-repo-1');
    routines = await repo.getRoutinesForDate('2026-08-15');
    expect(routines.first.status, ItemStatus.completed);

    // Revert item back to pending
    await repo.revertRoutine('item-repo-1');
    routines = await repo.getRoutinesForDate('2026-08-15');
    expect(routines.first.status, ItemStatus.pending);

    // Defer item
    await repo.deferRoutine('item-repo-1');
    routines = await repo.getRoutinesForDate('2026-08-15');
    expect(routines.first.timeWindow, TimeWindow.afternoon);

    // Delete item
    await repo.deleteRoutine('item-repo-1');
    routines = await repo.getRoutinesForDate('2026-08-15');
    expect(routines.isEmpty, true);
  });

  test(
    'offline repository automatically spawns habit on future date',
    () async {
      final now = DateTime.now();
      // Aug 15, 2026 is Saturday (weekday = 6)
      // Aug 16, 2026 is Sunday (weekday = 7)
      final item = RoutineItem(
        id: 'daily-creatine-1',
        title: 'Daily Creatine 5g',
        category: 'Meds/Supps',
        timeWindow: TimeWindow.morning,
        scheduledDate: '2026-08-15',
        status: ItemStatus.pending,
        metadata: {
          'dosage': '5g',
          'reminder': {
            'enabled': true,
            'time': '08:00',
            'days_of_week': [1, 2, 3, 4, 5, 6, 7],
          },
        },
        updatedAt: now,
        createdAt: now,
      );

      await repo.createRoutine(item);

      // Initial query on 2026-08-15
      final todayRoutines = await repo.getRoutinesForDate('2026-08-15');
      expect(todayRoutines.length, 1);
      expect(todayRoutines.first.title, 'Daily Creatine 5g');

      // Query on future date 2026-08-16
      final futureRoutines = await repo.getRoutinesForDate('2026-08-16');
      expect(futureRoutines.length, 1);
      expect(futureRoutines.first.title, 'Daily Creatine 5g');
      expect(futureRoutines.first.scheduledDate, '2026-08-16');
      expect(futureRoutines.first.status, ItemStatus.pending);
      expect(futureRoutines.first.metadata['dosage'], '5g');
    },
  );

  test('offline repository respects weekday recurrence filter', () async {
    final now = DateTime.now();
    // Aug 17, 2026 is Monday (weekday = 1)
    // Aug 16, 2026 is Sunday (weekday = 7)
    final weekdayItem = RoutineItem(
      id: 'work-focus-1',
      title: 'Work Standup',
      category: 'Focus',
      timeWindow: TimeWindow.morning,
      scheduledDate: '2026-08-17',
      status: ItemStatus.pending,
      metadata: {
        'reminder': {
          'enabled': true,
          'time': '09:00',
          'days_of_week': [1, 2, 3, 4, 5],
        }, // Mon-Fri
      },
      updatedAt: now,
      createdAt: now,
    );

    await repo.createRoutine(weekdayItem);

    // Should spawn on Monday 2026-08-17
    final monRoutines = await repo.getRoutinesForDate('2026-08-17');
    expect(monRoutines.any((r) => r.title == 'Work Standup'), isTrue);

    // Should NOT spawn on Sunday 2026-08-16
    final sunRoutines = await repo.getRoutinesForDate('2026-08-16');
    expect(sunRoutines.any((r) => r.title == 'Work Standup'), isFalse);
  });

  test('offline repository updateRoutine with applyToFuture updates template and future instances', () async {
    final now = DateTime.now();
    final item = RoutineItem(
      id: 'habit-edit-1',
      title: 'Water 1L',
      category: 'Nutrition',
      timeWindow: TimeWindow.morning,
      scheduledDate: '2026-08-15',
      status: ItemStatus.pending,
      updatedAt: now,
      createdAt: now,
    );

    await repo.createRoutine(item);

    // Spawn tomorrow's instance
    await repo.getRoutinesForDate('2026-08-16');

    // Update today's instance with applyToFuture: true
    final updatedItem = item.copyWith(
      title: 'Water 2L Hydration',
      metadata: {'dosage': '2000ml'},
    );
    await repo.updateRoutine(updatedItem, applyToFuture: true);

    // Verify today's item updated
    final todayRoutines = await repo.getRoutinesForDate('2026-08-15');
    expect(todayRoutines.first.title, 'Water 2L Hydration');

    // Verify tomorrow's item updated
    final tomorrowRoutines = await repo.getRoutinesForDate('2026-08-16');
    expect(tomorrowRoutines.first.title, 'Water 2L Hydration');
  });

  test('offline repository auto-migrates un-templated legacy habit and spawns tomorrow', () async {
    final now = DateTime.now();
    // Directly insert legacy row into DB without templateId
    await db.routineDao.upsertRoutine(
      RoutineItemsTableCompanion.insert(
        id: 'legacy-creatine',
        title: 'Legacy Creatine',
        category: 'Meds/Supps',
        timeWindow: 'MORNING',
        scheduledDate: '2026-08-15',
        status: const Value('PENDING'),
        updatedAt: now,
        createdAt: now,
      ),
    );

    // Watch tomorrow's routines
    final tomorrowRoutines = await repo
        .watchRoutinesForDate('2026-08-16')
        .first;
    expect(tomorrowRoutines.length, 1);
    expect(tomorrowRoutines.first.title, 'Legacy Creatine');
    expect(tomorrowRoutines.first.scheduledDate, '2026-08-16');
  });
}
