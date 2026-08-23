import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:pos_frontend/domain/models/routine_item.dart';
import 'package:pos_frontend/domain/models/streak_stats.dart';

RoutineItem _item({
  required String templateId,
  required DateTime date,
  required ItemStatus status,
}) {
  final d = DateTime(date.year, date.month, date.day);
  return RoutineItem(
    id: '$templateId-${DateFormat('yyyy-MM-dd').format(d)}',
    templateId: templateId,
    title: 'Habit',
    category: 'HABIT',
    timeWindow: TimeWindow.morning,
    scheduledDate: DateFormat('yyyy-MM-dd').format(d),
    status: status,
    updatedAt: d,
    createdAt: d,
  );
}

void main() {
  group('HabitStreakCalculator', () {
    final today = DateTime(2026, 8, 23);
    List<RoutineItem> histFor(Map<int, ItemStatus> byDaysAgo) =>
        byDaysAgo.entries
            .map(
              (e) => _item(
                templateId: 'tpl_1',
                date: today.subtract(Duration(days: e.key)),
                status: e.value,
              ),
            )
            .toList();

    test('empty history yields zeroed stats and all-notScheduled heatmap', () {
      final stats = HabitStreakCalculator.compute(
        templateId: 'tpl_1',
        history: const [],
        today: today,
      );

      expect(stats.templateId, 'tpl_1');
      expect(stats.currentStreak, 0);
      expect(stats.bestStreak, 0);
      expect(stats.completionRate30d, 0.0);
      expect(stats.last7Days.length, 7);
      expect(stats.last7Days.every((o) => o == DayOutcome.notScheduled),
          isTrue);
    });

    test('consecutive completions through today extend the streak', () {
      final stats = HabitStreakCalculator.compute(
        templateId: 'tpl_1',
        history: histFor({
          0: ItemStatus.completed,
          1: ItemStatus.completed,
          2: ItemStatus.completed,
          3: ItemStatus.completed,
        }),
        today: today,
      );

      expect(stats.currentStreak, 4);
      expect(stats.bestStreak, 4);
      expect(stats.completionRate30d, closeTo(1.0, 0.001));
    });

    test('a missed past day breaks the current streak', () {
      final stats = HabitStreakCalculator.compute(
        templateId: 'tpl_1',
        history: histFor({
          0: ItemStatus.completed,
          1: ItemStatus.missed,
          2: ItemStatus.completed,
        }),
        today: today,
      );

      expect(stats.currentStreak, 1);
      expect(stats.bestStreak, 1);
    });

    test('skipped day is neutral: preserves but does not extend streak', () {
      final stats = HabitStreakCalculator.compute(
        templateId: 'tpl_1',
        history: histFor({
          0: ItemStatus.completed,
          1: ItemStatus.skipped,
          2: ItemStatus.completed,
          3: ItemStatus.completed,
        }),
        today: today,
      );

      expect(stats.currentStreak, 3);
      expect(stats.bestStreak, 3);
      expect(stats.last7Days[5], DayOutcome.skipped); // 2 days ago
    });

    test('pending today does not break an existing streak', () {
      final stats = HabitStreakCalculator.compute(
        templateId: 'tpl_1',
        history: histFor({
          0: ItemStatus.pending,
          1: ItemStatus.completed,
          2: ItemStatus.completed,
        }),
        today: today,
      );

      expect(stats.currentStreak, 2);
      expect(stats.last7Days.last, DayOutcome.pending);
    });

    test('best streak spans across an earlier broken run', () {
      final stats = HabitStreakCalculator.compute(
        templateId: 'tpl_1',
        history: histFor({
          0: ItemStatus.pending,
          1: ItemStatus.completed,
          2: ItemStatus.completed,
          3: ItemStatus.completed,
          4: ItemStatus.completed,
          5: ItemStatus.completed,
          6: ItemStatus.missed,
          7: ItemStatus.completed,
          8: ItemStatus.completed,
          9: ItemStatus.completed,
        }),
        today: today,
      );

      expect(stats.currentStreak, 5);
      expect(stats.bestStreak, 5);
    });

    test('unscheduled days appear as notScheduled and are skipped over', () {
      // Mon/Wed/Fri habit: Aug 17, 19, 21 done; today Sun Aug 23 has no item.
      final history = [
        _item(templateId: 'tpl_1', date: DateTime(2026, 8, 17),
            status: ItemStatus.completed),
        _item(templateId: 'tpl_1', date: DateTime(2026, 8, 19),
            status: ItemStatus.completed),
        _item(templateId: 'tpl_1', date: DateTime(2026, 8, 21),
            status: ItemStatus.completed),
      ];

      final stats = HabitStreakCalculator.compute(
        templateId: 'tpl_1',
        history: history,
        today: today,
      );

      expect(stats.currentStreak, 3);
      expect(stats.last7Days.last, DayOutcome.notScheduled);
      expect(stats.last7Days[2], DayOutcome.completed); // Friday Aug 21
    });

    test('completion rate counts only items within the trailing 30 days', () {
      final history = [
        ...histFor({
          0: ItemStatus.completed,
          10: ItemStatus.missed,
          20: ItemStatus.completed,
        }),
        _item(
          templateId: 'tpl_1',
          date: today.subtract(const Duration(days: 40)),
          status: ItemStatus.completed,
        ),
      ];

      final stats = HabitStreakCalculator.compute(
        templateId: 'tpl_1',
        history: history,
        today: today,
      );

      expect(stats.completionRate30d, closeTo(2 / 3, 0.001));
    });

    test('heatmap maps every status outcome across the trailing week', () {
      final stats = HabitStreakCalculator.compute(
        templateId: 'tpl_1',
        history: histFor({
          0: ItemStatus.pending,
          1: ItemStatus.missed,
          2: ItemStatus.skipped,
          3: ItemStatus.completed,
        }),
        today: today,
      );

      expect(stats.last7Days[6], DayOutcome.pending);
      expect(stats.last7Days[5], DayOutcome.missed);
      expect(stats.last7Days[4], DayOutcome.skipped);
      expect(stats.last7Days[3], DayOutcome.completed);
      expect(stats.last7Days.take(3).every((o) => o == DayOutcome.notScheduled),
          isTrue);
    });
  });
}
