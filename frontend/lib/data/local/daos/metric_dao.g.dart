// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metric_dao.dart';

// ignore_for_file: type=lint
mixin _$MetricDaoMixin on DatabaseAccessor<AppDatabase> {
  $HealthMetricsTableTable get healthMetricsTable =>
      attachedDatabase.healthMetricsTable;
  MetricDaoManager get managers => MetricDaoManager(this);
}

class MetricDaoManager {
  final _$MetricDaoMixin _db;
  MetricDaoManager(this._db);
  $$HealthMetricsTableTableTableManager get healthMetricsTable =>
      $$HealthMetricsTableTableTableManager(
          _db.attachedDatabase, _db.healthMetricsTable);
}
