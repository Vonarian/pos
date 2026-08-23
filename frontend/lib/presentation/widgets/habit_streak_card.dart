import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/streak_stats.dart';
import '../providers/streak_provider.dart';
import 'streak_heatmap_row.dart';

/// Card showing a habit's current streak, best streak, 30-day rate and
/// trailing-week adherence heatmap.
class HabitStreakCard extends ConsumerWidget {
  final String templateId;
  final String title;

  const HabitStreakCard({
    super.key,
    required this.templateId,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(habitStreakStatsProvider(templateId));
    return statsAsync.when(
      data: (stats) => _buildCard(context, stats),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(BuildContext context, StreakStats stats) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StreakBadge(count: stats.currentStreak),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Best: ${stats.bestStreak} · '
            '${(stats.completionRate30d * 100).round()}% last 30 days',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 10),
          StreakHeatmapRow(days: stats.last7Days),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int count;

  const _StreakBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded,
              size: 16, color: scheme.primary),
          const SizedBox(width: 4),
          Text(
            '$count day streak',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
