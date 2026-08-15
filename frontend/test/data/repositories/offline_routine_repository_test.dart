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
}
