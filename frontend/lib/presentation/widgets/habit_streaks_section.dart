import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../providers/streak_provider.dart';
import 'habit_streak_card.dart';

/// "Habit Streaks" section listing one streak card per active recurring
/// habit; renders nothing when no recurring templates exist.
class HabitStreaksSection extends ConsumerWidget {
  const HabitStreaksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(activeTemplatesProvider);
    return templatesAsync.when(
      data: (templates) => templates.isEmpty
          ? const SizedBox.shrink()
          : _buildList(context, templates),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<RoutineTemplatesTableData> templates,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Habit Streaks',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        ...templates.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HabitStreakCard(templateId: t.id, title: t.title),
          ),
        ),
      ],
    );
  }
}
