import 'routine_item.dart';

/// Visual/semantic outcome of a habit on a specific calendar day.
enum DayOutcome { completed, missed, skipped, pending, notScheduled }

/// Immutable per-habit adherence statistics derived from retained history.
class StreakStats {
  final String templateId;
  final int currentStreak;
  final int bestStreak;
  final double completionRate30d;

  /// Trailing 7 days inclusive of today, ordered oldest -> newest.
  final List<DayOutcome> last7Days;

  const StreakStats({
    required this.templateId,
    required this.currentStreak,
    required this.bestStreak,
    required this.completionRate30d,
    required this.last7Days,
  });
}

/// Pure calculator turning routine history into [StreakStats].
///
/// Rules: COMPLETED extends a streak; SKIPPED and PENDING-today are
/// neutral (preserve); MISSED / past-PENDING break it. Days without an
/// item are not scheduled and are ignored entirely.
class HabitStreakCalculator {
  static StreakStats compute({
    required String templateId,
    required List<RoutineItem> history,
    required DateTime today,
  }) {
    final todayDate = _day(today);
    final byDate = _indexByDate(history);

    return StreakStats(
      templateId: templateId,
      currentStreak: _currentStreak(byDate, todayDate),
      bestStreak: _bestStreak(byDate, todayDate),
      completionRate30d: _rate30(byDate, todayDate),
      last7Days: _heatmap(byDate, todayDate),
    );
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static Map<DateTime, ItemStatus> _indexByDate(List<RoutineItem> history) {
    final byDate = <DateTime, ItemStatus>{};
    for (final item in history) {
      byDate[_parseDate(item.scheduledDate)] = item.status;
    }
    return byDate;
  }

  static DateTime _parseDate(String iso) {
    final parts = iso.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Single chronological scan; returns the live streak at today.
  static List<int> _scanStreaks(
    Map<DateTime, ItemStatus> byDate,
    DateTime today,
  ) {
    final days = byDate.keys.where((d) => !d.isAfter(today)).toList()..sort();
    int best = 0;
    int run = 0;
    for (final day in days) {
      switch (byDate[day]) {
        case ItemStatus.completed:
          run++;
          break;
        case ItemStatus.skipped:
          break; // neutral: preserves run without extending
        case ItemStatus.pending:
          if (!day.isAtSameMomentAs(today)) run = 0;
          break;
        case ItemStatus.missed:
          run = 0;
          break;
        default:
          break;
      }
      if (run > best) best = run;
    }
    return [run, best];
  }

  static int _currentStreak(
    Map<DateTime, ItemStatus> byDate,
    DateTime today,
  ) =>
      _scanStreaks(byDate, today)[0];

  static int _bestStreak(
    Map<DateTime, ItemStatus> byDate,
    DateTime today,
  ) =>
      _scanStreaks(byDate, today)[1];

  static double _rate30(
    Map<DateTime, ItemStatus> byDate,
    DateTime today,
  ) {
    final cutoff = today.subtract(const Duration(days: 29));
    var scheduled = 0;
    var done = 0;
    byDate.forEach((day, status) {
      if (day.isBefore(cutoff) || day.isAfter(today)) return;
      scheduled++;
      if (status == ItemStatus.completed) done++;
    });
    return scheduled == 0 ? 0.0 : done / scheduled;
  }

  static List<DayOutcome> _heatmap(
    Map<DateTime, ItemStatus> byDate,
    DateTime today,
  ) {
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final status = byDate[day];
      if (status == null) return DayOutcome.notScheduled;
      switch (status) {
        case ItemStatus.completed:
          return DayOutcome.completed;
        case ItemStatus.skipped:
          return DayOutcome.skipped;
        case ItemStatus.missed:
          return DayOutcome.missed;
        case ItemStatus.pending:
          return DayOutcome.pending;
      }
    });
  }
}
