import 'dart:convert';

import 'package:drift/drift.dart';

import '../local/database.dart';
import '../remote/api_client.dart';
import '../../domain/models/routine_item.dart';
import '../native/notification_service.dart';
import 'offline_routine_mapper.dart';
import 'offline_routine_spawner.dart';
import 'offline_routine_sync_handler.dart';

class OfflineRoutineRepository {
  final AppDatabase db;
  final ApiClient? apiClient;

  OfflineRoutineRepository({required this.db, this.apiClient});

  Stream<List<RoutineItem>> watchRoutinesForDate(String date) async* {
    await OfflineRoutineSpawner.ensureSpawnedForDate(db, date);
    yield* db.routineDao.watchRoutinesForDate(date).map((rows) {
      return rows.map(OfflineRoutineMapper.mapRowToDomain).toList();
    });
  }

  Future<List<RoutineItem>> getRoutinesForDate(String date) async {
    await OfflineRoutineSpawner.ensureSpawnedForDate(db, date);
    final rows = await db.routineDao.getRoutinesForDate(date);
    return rows.map(OfflineRoutineMapper.mapRowToDomain).toList();
  }

  Future<List<RoutineItem>> getRoutineHistoryByTemplate(
    String templateId,
  ) async {
    final rows = await db.routineDao.getRoutinesByTemplateId(templateId);
    return rows.map(OfflineRoutineMapper.mapRowToDomain).toList();
  }

  Stream<List<RoutineItem>> watchRoutineHistoryByTemplate(String templateId) {
    return db.routineDao.watchRoutinesByTemplateId(templateId).map((rows) {
      return rows.map(OfflineRoutineMapper.mapRowToDomain).toList();
    });
  }

  Future<void> _syncAction(Future<void> Function() call, String id) async {
    if (apiClient == null) return;
    try {
      await call();
      await db.routineDao.markAsSynced([id]);
    } catch (_) {}
  }

  Future<void> completeRoutine(String id, {DateTime? completedAt}) async {
    final now = completedAt ?? DateTime.now();
    await db.routineDao.updateStatus(id, 'COMPLETED', now);
    await _syncAction(() => apiClient!.completeRoutine(id, completedAt: now), id);
  }

  Future<void> skipRoutine(String id) async {
    await db.routineDao.updateStatus(id, 'SKIPPED', null);
    await _syncAction(() => apiClient!.skipRoutine(id), id);
  }

  Future<void> revertRoutine(String id) async {
    await db.routineDao.updateStatus(id, 'PENDING', null);
    await _syncAction(() => apiClient!.revertRoutine(id), id);
  }

  Future<void> deleteRoutine(String id, {bool deleteEverywhere = true}) async {
    final item = await db.routineDao.getRoutineById(id);
    await NativeNotificationService.cancelHabitReminder(id);
    await db.routineDao.deleteRoutine(id);

    final tplId = item?.templateId ?? 'tpl_$id';
    if (deleteEverywhere) {
      final matching = await db.routineDao.getRoutinesByTemplateId(tplId);
      for (final r in matching) {
        await NativeNotificationService.cancelHabitReminder(r.id);
      }
      await db.routineTemplateDao.deactivateTemplate(tplId);
      await db.routineDao.deleteRoutinesByTemplateId(tplId);
    }
  }

  Future<void> updateRoutine(
    RoutineItem item, {
    bool applyToFuture = true,
  }) async {
    if (item.reminderConfig?.enabled == false) {
      await NativeNotificationService.cancelHabitReminder(item.id);
    }
    final existing = await db.routineDao.getRoutineById(item.id);
    final effectiveTemplateId =
        item.templateId ?? existing?.templateId ?? 'tpl_${item.id}';
    final itemToSave = item.copyWith(templateId: effectiveTemplateId);

    await db.routineDao.upsertRoutine(
      OfflineRoutineMapper.mapDomainToCompanion(itemToSave, isSynced: false),
    );

    if (applyToFuture) {
      final days = (item.reminderConfig?.daysOfWeek.isNotEmpty ?? false)
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

    await _syncAction(
      () => apiClient!.pushSync(routines: [itemToSave], metrics: []),
      itemToSave.id,
    );
  }

  Future<void> deferRoutine(String id) async {
    final item = await db.routineDao.getRoutineById(id);
    if (item == null) return;

    final cur = TimeWindow.fromString(item.timeWindow);
    final next = cur == TimeWindow.morning
        ? TimeWindow.afternoon
        : (cur == TimeWindow.afternoon ? TimeWindow.evening : TimeWindow.night);
    await db.routineDao.updateTimeWindow(id, next.value);
    await _syncAction(() => apiClient!.deferRoutine(id), id);
  }

  Future<void> createRoutine(RoutineItem item) async {
    final shouldTemplate = item.templateId != null || item.isRecurring;
    String? templateId = item.templateId;

    if (shouldTemplate) {
      templateId ??= 'tpl_${item.id}';
      final days = (item.reminderConfig?.daysOfWeek.isNotEmpty ?? false)
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
    }

    final itemToSave = templateId != null
        ? item.copyWith(templateId: templateId)
        : item;

    await db.routineDao.upsertRoutine(
      OfflineRoutineMapper.mapDomainToCompanion(itemToSave, isSynced: false),
    );

    if (apiClient != null) {
      try {
        await apiClient!.pushSync(routines: [itemToSave], metrics: []);
        await db.routineDao.markAsSynced([itemToSave.id]);
      } catch (_) {}
    }
  }

  Future<void> syncWithServer() async {
    await OfflineRoutineSyncHandler.syncWithServer(db, apiClient);
  }
}
