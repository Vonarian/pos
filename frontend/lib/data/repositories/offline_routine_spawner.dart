import 'dart:convert';

import 'package:drift/drift.dart';

import '../local/database.dart';
import 'offline_routine_mapper.dart';

class OfflineRoutineSpawner {
  static Future<void> ensureSpawnedForDate(
    AppDatabase db,
    String dateStr,
  ) async {
    try {
      final date = DateTime.parse(dateStr);
      final weekday = date.weekday;

      // Migrate / self-heal any existing habits that don't have templates
      final allRoutines = await db.routineDao.getAllRoutines();
      final activeTemplates = await db.routineTemplateDao.getActiveTemplates();
      final activeTemplateIds = activeTemplates.map((t) => t.id).toSet();

      for (final r in allRoutines) {
        final tplId = r.templateId ?? 'tpl_${r.id}';
        if (!activeTemplateIds.contains(tplId)) {
          final domain = OfflineRoutineMapper.mapRowToDomain(r);
          final days = (domain.reminderConfig?.daysOfWeek.isNotEmpty ?? false)
              ? domain.reminderConfig!.daysOfWeek
              : const [1, 2, 3, 4, 5, 6, 7];

          await db.routineTemplateDao.upsertTemplate(
            RoutineTemplatesTableCompanion.insert(
              id: tplId,
              title: r.title,
              category: r.category,
              timeWindow: r.timeWindow,
              daysOfWeekJson: Value(jsonEncode(days)),
              metadataJson: Value(r.metadataJson),
              isActive: const Value(true),
              createdAt: r.createdAt,
              updatedAt: r.updatedAt,
              isSynced: const Value(false),
            ),
          );

          if (r.templateId == null) {
            await db.routineDao.upsertRoutine(
              r.toCompanion(true).copyWith(templateId: Value(tplId)),
            );
          }
          activeTemplateIds.add(tplId);
        }
      }

      final freshTemplates = await db.routineTemplateDao.getActiveTemplates();
      if (freshTemplates.isEmpty) return;

      final existingRows = await db.routineDao.getRoutinesForDate(dateStr);
      final existingTemplateIds = existingRows
          .map((r) => r.templateId)
          .where((id) => id != null)
          .toSet();

      final companionsToInsert = <RoutineItemsTableCompanion>[];
      final now = DateTime.now();

      for (final tpl in freshTemplates) {
        List<int> days = const [1, 2, 3, 4, 5, 6, 7];
        try {
          days = (jsonDecode(tpl.daysOfWeekJson) as List)
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
