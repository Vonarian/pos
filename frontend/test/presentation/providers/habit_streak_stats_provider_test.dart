import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:pos_frontend/data/local/database.dart';
import 'package:pos_frontend/domain/models/streak_stats.dart';
import 'package:pos_frontend/presentation/providers/routine_provider.dart';
import 'package:pos_frontend/presentation/providers/streak_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  String fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> seedItem(String templateId, DateTime date, String status) {
    final now = DateTime.now();
    return db.routineDao.upsertRoutine(
      RoutineItemsTableCompanion.insert(
        id: '$templateId-${fmt(date)}',
        templateId: Value(templateId),
        title: 'Meditate',
        category: 'HABIT',
        timeWindow: 'MORNING',
        scheduledDate: fmt(date),
        status: Value(status),
        updatedAt: now,
        createdAt: now,
        isSynced: const Value(false),
      ),
    );
  }

  Future<void> seedTemplate(String id) {
    final now = DateTime.now();
    return db.routineTemplateDao.upsertTemplate(
      RoutineTemplatesTableCompanion.insert(
        id: id,
        title: 'Meditate',
        category: 'HABIT',
        timeWindow: 'MORNING',
        updatedAt: now,
        createdAt: now,
        isSynced: const Value(false),
      ),
    );
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('streak providers', () {
    test(
      'habitStreakStatsProvider emits computed stats and reacts to updates',
      () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        await seedTemplate('tpl_1');
        await seedItem('tpl_1', yesterday, 'COMPLETED');

        // Keep the autoDispose provider alive while we await emissions.
        container.listen(habitStreakStatsProvider('tpl_1'), (_, __) {});

        var stats =
            await container.read(habitStreakStatsProvider('tpl_1').future);
        expect(stats.currentStreak, 1);

        // Completing today extends the streak reactively.
        final streakDone = Completer<StreakStats>();
        container.listen(habitStreakStatsProvider('tpl_1'), (_, next) {
          if (!streakDone.isCompleted &&
              next.value?.currentStreak == 2) {
            streakDone.complete(next.value);
          }
        });

        final todayItem = 'tpl_1-${fmt(DateTime.now())}';
        await seedItem('tpl_1', DateTime.now(), 'PENDING');
        await db.routineDao.updateStatus(todayItem, 'COMPLETED', DateTime.now());

        final updated = await streakDone.future;
        expect(updated.currentStreak, 2);
      },
    );

    test('activeTemplatesProvider exposes active recurring templates', () async {
      await seedTemplate('tpl_2');

      container.listen(activeTemplatesProvider, (_, __) {});

      final templates =
          await container.read(activeTemplatesProvider.future);

      expect(templates.map((t) => t.id), contains('tpl_2'));
    });
  });
}
