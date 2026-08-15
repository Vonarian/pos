import 'package:drift/drift.dart';

import '../database.dart';

part 'routine_dao.g.dart';

@DriftAccessor(tables: [RoutineItemsTable])
class RoutineDao extends DatabaseAccessor<AppDatabase> with _$RoutineDaoMixin {
  RoutineDao(super.db);

  Future<List<RoutineItemsTableData>> getRoutinesForDate(String date) {
    return (select(routineItemsTable)
          ..where((tbl) => tbl.scheduledDate.equals(date))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  Stream<List<RoutineItemsTableData>> watchRoutinesForDate(String date) {
    return (select(routineItemsTable)
          ..where((tbl) => tbl.scheduledDate.equals(date))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .watch();
  }

  Future<RoutineItemsTableData?> getRoutineById(String id) {
    return (select(
      routineItemsTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> upsertRoutine(RoutineItemsTableCompanion item) {
    return into(routineItemsTable).insertOnConflictUpdate(item);
  }

  Future<void> batchUpsertRoutines(
    List<RoutineItemsTableCompanion> items,
  ) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(routineItemsTable, items);
    });
  }

  Future<int> updateStatus(String id, String status, DateTime? completedAt) {
    return (update(routineItemsTable)..where((tbl) => tbl.id.equals(id))).write(
      RoutineItemsTableCompanion(
        status: Value(status),
        completedAt: Value(completedAt),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  Future<int> updateTimeWindow(String id, String timeWindow) {
    return (update(routineItemsTable)..where((tbl) => tbl.id.equals(id))).write(
      RoutineItemsTableCompanion(
        timeWindow: Value(timeWindow),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  Future<List<RoutineItemsTableData>> getUnsyncedRoutines() {
    return (select(
      routineItemsTable,
    )..where((tbl) => tbl.isSynced.equals(false))).get();
  }

  Future<void> markAsSynced(List<String> ids) {
    return (update(routineItemsTable)..where((tbl) => tbl.id.isIn(ids))).write(
      const RoutineItemsTableCompanion(isSynced: Value(true)),
    );
  }

  Future<int> resetPendingToMissed(String beforeDate) {
    return (update(routineItemsTable)..where(
          (tbl) =>
              tbl.scheduledDate.isSmallerThanValue(beforeDate) &
              tbl.status.equals('PENDING'),
        ))
        .write(
          RoutineItemsTableCompanion(
            status: const Value('MISSED'),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<int> deleteRoutine(String id) {
    return (delete(routineItemsTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> deleteRoutinesByTemplateId(String templateId) {
    return (delete(
      routineItemsTable,
    )..where((tbl) => tbl.templateId.equals(templateId))).go();
  }

  Future<int> updatePendingRoutinesByTemplateId({
    required String templateId,
    required String title,
    required String category,
    required String timeWindow,
    required String metadataJson,
  }) {
    return (update(routineItemsTable)..where(
          (tbl) =>
              tbl.templateId.equals(templateId) & tbl.status.equals('PENDING'),
        ))
        .write(
          RoutineItemsTableCompanion(
            title: Value(title),
            category: Value(category),
            timeWindow: Value(timeWindow),
            metadataJson: Value(metadataJson),
            updatedAt: Value(DateTime.now()),
            isSynced: const Value(false),
          ),
        );
  }
}
