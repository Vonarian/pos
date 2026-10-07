import 'dart:convert';

import 'package:drift/drift.dart';

import '../local/database.dart';
import '../../domain/models/routine_item.dart';
import 'offline_routine_mapper.dart';

class OfflineRoutineSpawner {
  static Future<void> ensureSpawnedForDate(
    AppDatabase db,
    String dateStr,
  ) async {
    try {
      final date = DateTime.parse(dateStr);
      await _selfHealTemplates(db);
      await _spawnTemplatesForDate(db, dateStr, date.weekday);
    } catch (_) {}
  }

  static Future<void> _selfHealTemplates(AppDatabase db) async {
    final allRoutines = await db.routineDao.getAllRoutines();
    final allTemplates = await db.routineTemplateDao.getAllTemplates();
    final knownTemplateIds = allTemplates.map((t) => t.id).toSet();

    for (final r in allRoutines) {
      final domain = OfflineRoutineMapper.mapRowToDomain(r);
      if (!domain.isRecurring) continue;

      final tplId = r.templateId ?? 'tpl_${r.id}';
      if (!knownTemplateIds.contains(tplId)) {
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
        knownTemplateIds.add(tplId);
      }
    }
  }

  static Future<void> _spawnTemplatesForDate(
    AppDatabase db,
    String dateStr,
    int weekday,
  ) async {
    final freshTemplates = await db.routineTemplateDao.getActiveTemplates();
    if (freshTemplates.isEmpty) return;

    final existingRows = await db.routineDao.getRoutinesForDate(dateStr);
    final existingTemplateIds = existingRows
        .map((r) => r.templateId)
        .where((id) => id != null)
        .toSet();

    final companions = <RoutineItemsTableCompanion>[];
    final now = DateTime.now();

    for (final tpl in freshTemplates) {
      List<int> days = const [1, 2, 3, 4, 5, 6, 7];
      try {
        days = (jsonDecode(tpl.daysOfWeekJson) as List)
            .map((e) => e as int)
            .toList();
      } catch (_) {}

      if (days.contains(weekday) && !existingTemplateIds.contains(tpl.id)) {
        companions.add(
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

    if (companions.isNotEmpty) {
      await db.routineDao.batchUpsertRoutines(companions);
    }
  }

  static Future<List<RoutineItem>> collectSchedulableRoutines(
    AppDatabase db,
    String todayDate,
  ) async {
    await ensureSpawnedForDate(db, todayDate);
    final allRows = await db.routineDao.getAllRoutines();
    final activeTemplates = await db.routineTemplateDao.getActiveTemplates();
    final result = <RoutineItem>[];
    final representedTemplates = <String>{};

    for (final row in allRows) {
      final isToday = row.scheduledDate == todayDate;
      final isFuturePending =
          row.scheduledDate.compareTo(todayDate) > 0 && row.status == 'PENDING';
      if (isToday || isFuturePending) {
        result.add(OfflineRoutineMapper.mapRowToDomain(row));
        if (row.templateId != null) {
          representedTemplates.add(row.templateId!);
        }
      }
    }

    for (final tpl in activeTemplates) {
      if (!representedTemplates.contains(tpl.id)) {
        result.add(_templateToSyntheticItem(tpl, todayDate));
      }
    }
    return result;
  }

  static RoutineItem _templateToSyntheticItem(
    RoutineTemplatesTableData tpl,
    String todayDate,
  ) {
    Map<String, dynamic> meta = {};
    try {
      meta = jsonDecode(tpl.metadataJson) as Map<String, dynamic>;
    } catch (_) {}
    return RoutineItem(
      id: '${tpl.id}_$todayDate',
      templateId: tpl.id,
      title: tpl.title,
      category: tpl.category,
      timeWindow: TimeWindow.fromString(tpl.timeWindow),
      scheduledDate: todayDate,
      status: ItemStatus.pending,
      metadata: meta,
      updatedAt: tpl.updatedAt,
      createdAt: tpl.createdAt,
    );
  }
}

