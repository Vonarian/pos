import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/data/local/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('upsert and query routine items by date', () async {
    final item = RoutineItemsTableCompanion.insert(
      id: 'test-1',
      title: 'Morning Creatine & D3',
      category: 'MEDS',
      timeWindow: 'MORNING',
      scheduledDate: '2026-08-15',
      status: const Value('PENDING'),
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await db.routineDao.upsertRoutine(item);
    final results = await db.routineDao.getRoutinesForDate('2026-08-15');

    expect(results.length, 1);
    expect(results.first.title, 'Morning Creatine & D3');
    expect(results.first.status, 'PENDING');
  });

  test('update status and defer routine item', () async {
    final now = DateTime.now();
    await db.routineDao.upsertRoutine(
      RoutineItemsTableCompanion.insert(
        id: 'test-2',
        title: 'Mid-Day Protein Shake',
        category: 'NUTRITION',
        timeWindow: 'AFTERNOON',
        scheduledDate: '2026-08-15',
        status: const Value('PENDING'),
        updatedAt: now,
        createdAt: now,
      ),
    );

    // Complete
    await db.routineDao.updateStatus('test-2', 'COMPLETED', now);
    var updated = await db.routineDao.getRoutineById('test-2');
    expect(updated?.status, 'COMPLETED');
    expect(updated?.completedAt != null, isTrue);

    // Defer
    await db.routineDao.updateTimeWindow('test-2', 'EVENING');
    updated = await db.routineDao.getRoutineById('test-2');
    expect(updated?.timeWindow, 'EVENING');
  });

  test('health metrics upsert and daily summary aggregation', () async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day, 8, 0);
    final end = DateTime(today.year, today.month, today.day, 9, 0);

    await db.metricDao.batchUpsertMetrics([
      HealthMetricsTableCompanion.insert(
        id: 'metric-1',
        source: 'health_connect',
        metric: 'STEPS',
        value: 4000.0,
        unit: 'count',
        startTime: start,
        endTime: end,
        syncedAt: DateTime.now(),
      ),
      HealthMetricsTableCompanion.insert(
        id: 'metric-2',
        source: 'health_connect',
        metric: 'STEPS',
        value: 3500.0,
        unit: 'count',
        startTime: start.add(const Duration(hours: 2)),
        endTime: end.add(const Duration(hours: 2)),
        syncedAt: DateTime.now(),
      ),
      HealthMetricsTableCompanion.insert(
        id: 'metric-3',
        source: 'health_connect',
        metric: 'CALORIES_BURNED',
        value: 500.0,
        unit: 'kcal',
        startTime: start,
        endTime: end,
        syncedAt: DateTime.now(),
      ),
    ]);

    final summary = await db.metricDao.getDailySummary(today);
    expect(summary['STEPS'], 7500.0);
    expect(summary['CALORIES_BURNED'], 500.0);
  });
}
