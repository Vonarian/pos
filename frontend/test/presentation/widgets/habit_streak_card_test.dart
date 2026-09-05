import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:pos_frontend/data/local/database.dart';
import 'package:pos_frontend/domain/models/streak_stats.dart';
import 'package:pos_frontend/presentation/providers/routine_provider.dart';
import 'package:pos_frontend/presentation/widgets/habit_streak_card.dart';
import 'package:pos_frontend/presentation/widgets/streak_heatmap_row.dart';

void main() {
  late AppDatabase db;

  String fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> seedHistory() async {
    final now = DateTime.now();
    await db.routineTemplateDao.upsertTemplate(
      RoutineTemplatesTableCompanion.insert(
        id: 'tpl_1',
        title: 'Meditate',
        category: 'HABIT',
        timeWindow: 'MORNING',
        updatedAt: now,
        createdAt: now,
        isSynced: const Value(false),
      ),
    );
    for (var i = 1; i <= 3; i++) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      await db.routineDao.upsertRoutine(
        RoutineItemsTableCompanion.insert(
          id: 'tpl_1-${fmt(date)}',
          templateId: const Value('tpl_1'),
          title: 'Meditate',
          category: 'HABIT',
          timeWindow: 'MORNING',
          scheduledDate: fmt(date),
          status: const Value('COMPLETED'),
          updatedAt: now,
          createdAt: now,
          isSynced: const Value(false),
        ),
      );
    }
  }

  Future<void> pumpCard(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(
          home: Scaffold(
            body: HabitStreakCard(templateId: 'tpl_1', title: 'Meditate'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Unmounts the tree and flushes drift's stream-cancel timer so the
  /// fake-async pending-timer invariant is not tripped at test end.
  Future<void> teardownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('HabitStreakCard', () {
    testWidgets('renders title, streak badge, best caption and heatmap',
        (tester) async {
      await seedHistory();
      await pumpCard(tester);

      expect(find.text('Meditate'), findsOneWidget);
      expect(find.text('3 day streak'), findsOneWidget);
      expect(find.textContaining('Best: 3'), findsOneWidget);
      expect(find.byType(StreakHeatmapRow), findsOneWidget);
      await teardownTree(tester);
    });

    testWidgets('heatmap shows one dot per trailing day', (tester) async {
      await seedHistory();
      await pumpCard(tester);

      for (var i = 0; i < 7; i++) {
        expect(find.byKey(ValueKey('streak_dot_$i')), findsOneWidget);
      }
      await teardownTree(tester);
    });
  });

  group('StreakHeatmapRow', () {
    Color dotColor(WidgetTester tester, int index) {
      final container = tester.widget<Container>(
        find.byKey(ValueKey('streak_dot_$index')),
      );
      return (container.decoration! as BoxDecoration).color!;
    }

    testWidgets('maps outcomes to theme colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          home: Scaffold(
            body: StreakHeatmapRow(days: [
              DayOutcome.completed,
              DayOutcome.missed,
              DayOutcome.skipped,
              DayOutcome.pending,
              DayOutcome.notScheduled,
              DayOutcome.completed,
              DayOutcome.pending,
            ]),
          ),
        ),
      );

      final scheme = Theme.of(tester.element(find.byType(StreakHeatmapRow)))
          .colorScheme;
      expect(dotColor(tester, 0), scheme.primary);
      expect(dotColor(tester, 1), scheme.error);
      expect(dotColor(tester, 2), const Color(0xFFFBBF24));
      expect(dotColor(tester, 3), scheme.outline);
      expect(dotColor(tester, 4), scheme.surfaceContainerHighest);
      expect(dotColor(tester, 5), scheme.primary);
    });
  });
}
