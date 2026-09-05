import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../domain/models/streak_stats.dart';
import 'routine_provider.dart';

/// Streams all active recurring-habit templates.
final activeTemplatesProvider =
    StreamProvider.autoDispose<List<RoutineTemplatesTableData>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.routineTemplateDao.watchActiveTemplates();
});

/// Streams live-computed streak statistics for a single habit template.
final habitStreakStatsProvider = StreamProvider.autoDispose
    .family<StreakStats, String>((ref, templateId) {
  final repo = ref.watch(offlineRoutineRepositoryProvider);
  return repo.watchRoutineHistoryByTemplate(templateId).map((history) {
    return HabitStreakCalculator.compute(
      templateId: templateId,
      history: history,
      today: DateTime.now(),
    );
  });
});
