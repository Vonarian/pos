import 'dart:convert';
import 'package:drift/drift.dart';

import '../local/database.dart';

class OfflineRoutineSpawner {
  static Future<void> ensureSpawnedForDate(
    AppDatabase db,
    String dateStr,
  ) async {
    try {
      final date = DateTime.parse(dateStr);
      final weekday = date.weekday;
      final activeTemplates = await db.routineTemplateDao.getActiveTemplates();
      if (activeTemplates.isEmpty) return;

      final existingRows = await db.routineDao.getRoutinesForDate(dateStr);
      final existingTemplateIds =
          existingRows
              .map((r) => r.templateId)
              .where((id) => id != null)
              .toSet();

      final companionsToInsert = <RoutineItemsTableCompanion>[];
      final now = DateTime.now();

      for (final tpl in activeTemplates) {
        List<int> days = const [1, 2, 3, 4, 5, 6, 7];
        try {
          days =
              (jsonDecode(tpl.daysOfWeekJson) as List)
                  .map((e) => e as int)
                  .toList();
        } catch (_) {}

        if (days.contains(weekday) && !existingTemplateIds.contains(tpl.id)) {
          companionsToInsert.add(
            RoutineItemsTableCompanion.insert(
              id: '${tpl.id}_$dateStr',
              templateId: Value(tpl.id),
              title: tpl.title,
              category: tpl.category,
              timeWindow: tpl.timeWindow,
              scheduledDate: dateStr,
              status: const Value('PENDING'),
              metadataJson: Value(tpl.metadataJson),
              updatedAt: now,
              createdAt: now,
              isSynced: const Value(false),
            ),
          );
        }
      }

      if (companionsToInsert.isNotEmpty) {
        await db.routineDao.batchUpsertRoutines(companionsToInsert);
      }
    } catch (_) {}
  }
}
