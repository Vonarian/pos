import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/streak_stats.dart';

/// Trailing 7-day adherence heatmap: one colored dot per day with a
/// weekday-initial caption underneath.
class StreakHeatmapRow extends StatelessWidget {
  final List<DayOutcome> days;

  const StreakHeatmapRow({super.key, required this.days});

  static const _skippedColor = Color(0xFFFBBF24);

  Color _colorFor(BuildContext context, DayOutcome outcome) {
    final scheme = Theme.of(context).colorScheme;
    switch (outcome) {
      case DayOutcome.completed:
        return scheme.primary;
      case DayOutcome.missed:
        return scheme.error;
      case DayOutcome.skipped:
        return _skippedColor;
      case DayOutcome.pending:
        return scheme.outline;
      case DayOutcome.notScheduled:
        return scheme.surfaceContainerHighest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: 6 - i));
        final color = _colorFor(context, days[i]);
        return Column(
          children: [
            Container(
              key: ValueKey('streak_dot_$i'),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.E().format(day).substring(0, 1),
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        );
      }),
    );
  }
}
