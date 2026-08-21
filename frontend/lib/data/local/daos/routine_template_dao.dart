import 'package:drift/drift.dart';

import '../database.dart';

part 'routine_template_dao.g.dart';

@DriftAccessor(tables: [RoutineTemplatesTable])
class RoutineTemplateDao extends DatabaseAccessor<AppDatabase>
    with _$RoutineTemplateDaoMixin {
  RoutineTemplateDao(super.db);

  Future<List<RoutineTemplatesTableData>> getActiveTemplates() {
    return (select(routineTemplatesTable)
          ..where((tbl) => tbl.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  Stream<List<RoutineTemplatesTableData>> watchActiveTemplates() {
    return (select(routineTemplatesTable)
          ..where((tbl) => tbl.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .watch();
  }

  Future<RoutineTemplatesTableData?> getTemplateById(String id) {
    return (select(
      routineTemplatesTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> upsertTemplate(RoutineTemplatesTableCompanion item) {
    return into(routineTemplatesTable).insertOnConflictUpdate(item);
  }

  Future<int> deactivateTemplate(String id) {
    return (update(
      routineTemplatesTable,
    )..where((tbl) => tbl.id.equals(id))).write(
      RoutineTemplatesTableCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  Future<int> deleteTemplate(String id) {
    return (delete(
      routineTemplatesTable,
    )..where((tbl) => tbl.id.equals(id))).go();
  }
}
