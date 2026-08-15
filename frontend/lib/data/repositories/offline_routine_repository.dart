import 'dart:convert';
import 'package:drift/drift.dart';
import '../local/database.dart';
import '../remote/api_client.dart';
import '../../domain/models/routine_item.dart';

class OfflineRoutineRepository {
  final AppDatabase db;
  final ApiClient? apiClient;

  OfflineRoutineRepository({
    required this.db,
    this.apiClient,
  });

  Stream<List<RoutineItem>> watchRoutinesForDate(String date) {
    return db.routineDao.watchRoutinesForDate(date).map((rows) {
      return rows.map(_mapRowToDomain).toList();
    });
  }

  Future<List<RoutineItem>> getRoutinesForDate(String date) async {
    final rows = await db.routineDao.getRoutinesForDate(date);
    return rows.map(_mapRowToDomain).toList();
  }

  Future<void> completeRoutine(String id, {DateTime? completedAt}) async {
    final now = completedAt ?? DateTime.now();
    await db.routineDao.updateStatus(id, 'COMPLETED', now);

    // Optimistic background sync to API
    if (apiClient != null) {
      try {
        await apiClient!.completeRoutine(id, completedAt: now);
        await db.routineDao.markAsSynced([id]);
      } catch (_) {
        // Will sync later via background sync queue
      }
    }
  }

  Future<void> skipRoutine(String id) async {
    await db.routineDao.updateStatus(id, 'SKIPPED', null);

    if (apiClient != null) {
      try {
        await apiClient!.skipRoutine(id);
        await db.routineDao.markAsSynced([id]);
      } catch (_) {
        // Will sync later
      }
    }
  }

  Future<void> deferRoutine(String id) async {
    final item = await db.routineDao.getRoutineById(id);
    if (item == null) return;

    final currentWindow = TimeWindow.fromString(item.timeWindow);
    TimeWindow nextWindow;
    switch (currentWindow) {
      case TimeWindow.morning:
        nextWindow = TimeWindow.afternoon;
        break;
      case TimeWindow.afternoon:
        nextWindow = TimeWindow.evening;
        break;
      case TimeWindow.evening:
        nextWindow = TimeWindow.night;
        break;
      case TimeWindow.night:
        nextWindow = TimeWindow.night;
        break;
    }

    await db.routineDao.updateTimeWindow(id, nextWindow.value);

    if (apiClient != null) {
      try {
        await apiClient!.deferRoutine(id);
        await db.routineDao.markAsSynced([id]);
      } catch (_) {
        // Will sync later
      }
    }
  }

  Future<void> createRoutine(RoutineItem item) async {
    await db.routineDao.upsertRoutine(_mapDomainToCompanion(item, isSynced: false));

    if (apiClient != null) {
      try {
        await apiClient!.pushSync(routines: [item], metrics: []);
        await db.routineDao.markAsSynced([item.id]);
      } catch (_) {
        // Will sync later
      }
    }
  }

  Future<void> syncWithServer() async {
    if (apiClient == null) return;

    try {
      // 1. Push unsynced
      final unsynced = await db.routineDao.getUnsyncedRoutines();
      if (unsynced.isNotEmpty) {
        final domainItems = unsynced.map(_mapRowToDomain).toList();
        await apiClient!.pushSync(routines: domainItems, metrics: []);
        await db.routineDao.markAsSynced(domainItems.map((e) => e.id).toList());
      }

      // 2. Pull remote changes
      final pullData = await apiClient!.pullSync();
      if (pullData['routines'] != null) {
        final remoteRoutines = (pullData['routines'] as List)
            .map((e) => RoutineItem.fromJson(e as Map<String, dynamic>))
            .toList();

        final companions = remoteRoutines
            .map((e) => _mapDomainToCompanion(e, isSynced: true))
            .toList();

        await db.routineDao.batchUpsertRoutines(companions);
      }
    } catch (_) {
      // Network failure gracefully handled
    }
  }

  RoutineItem _mapRowToDomain(RoutineItemsTableData row) {
    Map<String, dynamic> meta = {};
    try {
      meta = jsonDecode(row.metadataJson) as Map<String, dynamic>;
    } catch (_) {}

    return RoutineItem(
      id: row.id,
      templateId: row.templateId,
      title: row.title,
      category: row.category,
      timeWindow: TimeWindow.fromString(row.timeWindow),
      scheduledDate: row.scheduledDate,
      status: ItemStatus.fromString(row.status),
      completedAt: row.completedAt,
      metadata: meta,
      updatedAt: row.updatedAt,
      createdAt: row.createdAt,
    );
  }

  RoutineItemsTableCompanion _mapDomainToCompanion(RoutineItem item, {bool isSynced = false}) {
    return RoutineItemsTableCompanion.insert(
      id: item.id,
      templateId: Value(item.templateId),
      title: item.title,
      category: item.category,
      timeWindow: item.timeWindow.value,
      scheduledDate: item.scheduledDate,
      status: Value(item.status.value),
      completedAt: Value(item.completedAt),
      metadataJson: Value(jsonEncode(item.metadata)),
      updatedAt: item.updatedAt,
      createdAt: item.createdAt,
      isSynced: Value(isSynced),
    );
  }
}
