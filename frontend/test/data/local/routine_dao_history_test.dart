import 'package:drift/drift.dart';
import 'package:drift/native.dart';
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

  Future<void> seedItem({
    required String id,
    required String templateId,
    required String date,
    String status = 'COMPLETED',
  }) {
    final now = DateTime.now();
    return db.routineDao.upsertRoutine(
      RoutineItemsTableCompanion.insert(
        id: id,
        templateId: Value(templateId),
        title: 'Habit $templateId',
        category: 'HABIT',
        timeWindow: 'MORNING',
        scheduledDate: date,
        status: Value(status),
        updatedAt: now,
        createdAt: now,
        isSynced: const Value(false),
      ),
    );
  }

  group('RoutineDao template history queries', () {
    test('getRoutinesByTemplateId filters by template and sorts by date',
        () async {
      await seedItem(id: 'a2', templateId: 'tpl_1', date: '2026-08-19');
      await seedItem(id: 'a1', templateId: 'tpl_1', date: '2026-08-17');
      await seedItem(id: 'b1', templateId: 'tpl_2', date: '2026-08-18');
      await seedItem(id: 'a0', templateId: 'other', date: '2026-08-16');

      final rows = await db.routineDao.getRoutinesByTemplateId('tpl_1');

      expect(rows.map((r) => r.id), ['a1', 'a2']);
      expect(rows.every((r) => r.templateId == 'tpl_1'), isTrue);
    });

    test('watchRoutinesByTemplateId emits updates on completion', () async {
      await seedItem(
          id: 'w1', templateId: 'tpl_9', date: '2026-08-20',
          status: 'PENDING');

      final first = await db.routineDao
          .watchRoutinesByTemplateId('tpl_9')
          .first
          .then((rows) => rows.single.status);

      expect(first, 'PENDING');

      await db.routineDao.updateStatus('w1', 'COMPLETED', DateTime.now());
      final second = await db.routineDao
          .watchRoutinesByTemplateId('tpl_9')
          .map((rows) => rows.single.status)
          .first;

      expect(second, 'COMPLETED');
    });

    test('returns empty list for unknown template id', () async {
      await seedItem(id: 'z1', templateId: 'tpl_1', date: '2026-08-17');

      final rows = await db.routineDao.getRoutinesByTemplateId('nope');

      expect(rows, isEmpty);
    });
  });
}
