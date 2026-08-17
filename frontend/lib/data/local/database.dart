import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'daos/routine_dao.dart';
import 'daos/routine_template_dao.dart';
import 'daos/metric_dao.dart';

part 'database.g.dart';

class RoutineTemplatesTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  TextColumn get timeWindow => text()();
  TextColumn get daysOfWeekJson =>
      text().withDefault(const Constant('[1,2,3,4,5,6,7]'))();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class RoutineItemsTable extends Table {
  TextColumn get id => text()();
  TextColumn get templateId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  TextColumn get timeWindow => text()();
  TextColumn get scheduledDate => text()();
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class HealthMetricsTable extends Table {
  TextColumn get id => text()();
  TextColumn get source => text()();
  TextColumn get metric => text()();
  RealColumn get value => real()();
  TextColumn get unit => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get externalId => text().nullable().unique()();
  DateTimeColumn get syncedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [RoutineTemplatesTable, RoutineItemsTable, HealthMetricsTable],
  daos: [RoutineTemplateDao, RoutineDao, MetricDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(routineTemplatesTable);
        try {
          await m.addColumn(routineItemsTable, routineItemsTable.templateId);
        } catch (_) {}
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pos_local.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
