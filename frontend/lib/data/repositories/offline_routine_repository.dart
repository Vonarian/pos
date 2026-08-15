import 'dart:convert';
import 'package:drift/drift.dart';

import '../local/database.dart';
import '../remote/api_client.dart';
import '../../domain/models/routine_item.dart';
import 'offline_routine_mapper.dart';
import 'offline_routine_spawner.dart';
import 'offline_routine_sync_handler.dart';

class OfflineRoutineRepository {
  final AppDatabase db;
  final ApiClient? apiClient;

  OfflineRoutineRepository({required this.db, this.apiClient});

  Stream<List<RoutineItem>> watchRoutinesForDate(String date) {
    OfflineRoutineSpawner.ensureSpawnedForDate(db, date);
    return db.routineDao.watchRoutinesForDate(date).map((rows) {
      return rows.map(OfflineRoutineMapper.mapRowToDomain).toList();
    });
  }

  Future<List<RoutineItem>> getRoutinesForDate(String date) async {
    await OfflineRoutineSpawner.ensureSpawnedForDate(db, date);
    final rows = await db.routineDao.getRoutinesForDate(date);
    return rows.map(OfflineRoutineMapper.mapRowToDomain).toList();
  }

  Future<void> completeRoutine(String id, {DateTime? completedAt}) async {
    final now = completedAt ?? DateTime.now();
    await db.routineDao.updateStatus(id, 'COMPLETED', now);

    if (apiClient != null) {
      try {
        await apiClient!.completeRoutine(id, completedAt: now);
        await db.routineDao.markAsSynced([id]);
      } catch (_) {}
    }
  }

  Future<void> skipRoutine(String id) async {
    await db.routineDao.updateStatus(id, 'SKIPPED', null);

    if (apiClient != null) {
      try {
        await apiClient!.skipRoutine(id);
        await db.routineDao.markAsSynced([id]);
      } catch (_) {}
    }
  }

  Future<void> revertRoutine(String id) async {
    await db.routineDao.updateStatus(id, 'PENDING', null);

    if (apiClient != null) {
      try {
        await apiClient!.revertRoutine(id);
        await db.routineDao.markAsSynced([id]);
      } catch (_) {}
    }
  }

  Future<void> deleteRoutine(String id, {bool deleteEverywhere = true}) async {
    final item = await db.routineDao.getRoutineById(id);
    await db.routineDao.deleteRoutine(id);

    if (deleteEverywhere && item?.templateId != null) {
      await db.routineTemplateDao.deactivateTemplate(item!.templateId!);
      await db.routineDao.deleteRoutinesByTemplateId(item.templateId!);
    }
  }

  Future<void> updateRoutine(RoutineItem item, {bool applyToFuture = true}) async {
    final existing = await db.routineDao.getRoutineById(item.id);
    final effectiveTemplateId = item.templateId ?? existing?.templateId;
    final itemToSave = item.copyWith(templateId: effectiveTemplateId);

    await db.routineDao.upsertRoutine(
      OfflineRoutineMapper.mapDomainToCompanion(itemToSave, isSynced: false),
    );

    if (applyToFuture && effectiveTemplateId != null) {
      final days =
          (item.reminderConfig?.daysOfWeek.isNotEmpty ?? false)
              ? item.reminderConfig!.daysOfWeek
              : const [1, 2, 3, 4, 5, 6, 7];

      await db.routineTemplateDao.upsertTemplate(
        RoutineTemplatesTableCompanion.insert(
          id: effectiveTemplateId,
          title: item.title,
          category: item.category,
          timeWindow: item.timeWindow.value,
          daysOfWeekJson: Value(jsonEncode(days)),
          metadataJson: Value(jsonEncode(item.metadata)),
          isActive: const Value(true),
          createdAt: item.createdAt,
          updatedAt: DateTime.now(),
          isSynced: const Value(false),
        ),
      );

      await db.routineDao.updatePendingRoutinesByTemplateId(
        templateId: effectiveTemplateId,
        title: item.title,
        category: item.category,
        timeWindow: item.timeWindow.value,
        metadataJson: jsonEncode(item.metadata),
      );
    }

    if (apiClient != null) {
      try {
        await apiClient!.pushSync(routines: [itemToSave], metrics: []);
        await db.routineDao.markAsSynced([itemToSave.id]);
      } catch (_) {}
    }
  }

  Future<void> deferRoutine(String id) async {
    final item = await db.routineDao.getRoutineById(id);
    if (item == null) return;

    final currentWindow = TimeWindow.fromString(item.timeWindow);
    TimeWindow nextWindow = currentWindow;
    switch (currentWindow) {
      case TimeWindow.morning:
        nextWindow = TimeWindow.afternoon;
        break;
      case TimeWindow.afternoon:
        nextWindow = TimeWindow.evening;
        break;
      case TimeWindow.evening:
      case TimeWindow.night:
        nextWindow = TimeWindow.night;
        break;
    }

    await db.routineDao.updateTimeWindow(id, nextWindow.value);

    if (apiClient != null) {
      try {
        await apiClient!.deferRoutine(id);
        await db.routineDao.markAsSynced([id]);
      } catch (_) {}
    }
  }

  Future<void> createRoutine(RoutineItem item) async {
    final templateId = item.templateId ?? 'tpl_${item.id}';
    final days =
        (item.reminderConfig?.daysOfWeek.isNotEmpty ?? false)
            ? item.reminderConfig!.daysOfWeek
            : const [1, 2, 3, 4, 5, 6, 7];

    await db.routineTemplateDao.upsertTemplate(
      RoutineTemplatesTableCompanion.insert(
        id: templateId,
        title: item.title,
        category: item.category,
        timeWindow: item.timeWindow.value,
        daysOfWeekJson: Value(jsonEncode(days)),
        metadataJson: Value(jsonEncode(item.metadata)),
        isActive: const Value(true),
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
        isSynced: const Value(false),
      ),
    );

    final itemWithTemplate = item.copyWith(templateId: templateId);
    await db.routineDao.upsertRoutine(
      OfflineRoutineMapper.mapDomainToCompanion(
        itemWithTemplate,
        isSynced: false,
      ),
    );

    if (apiClient != null) {
      try {
        await apiClient!.pushSync(routines: [itemWithTemplate], metrics: []);
        await db.routineDao.markAsSynced([itemWithTemplate.id]);
      } catch (_) {}
    }
  }

  Future<void> syncWithServer() async {
    await OfflineRoutineSyncHandler.syncWithServer(db, apiClient);
  }
}
