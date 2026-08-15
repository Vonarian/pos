import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'daos/routine_dao.dart';
import 'daos/metric_dao.dart';

part 'database.g.dart';

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
  tables: [RoutineItemsTable, HealthMetricsTable],
  daos: [RoutineDao, MetricDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pos_local.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
