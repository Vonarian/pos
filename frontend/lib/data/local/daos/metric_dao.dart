import 'package:drift/drift.dart';

import '../database.dart';

part 'metric_dao.g.dart';

@DriftAccessor(tables: [HealthMetricsTable])
class MetricDao extends DatabaseAccessor<AppDatabase> with _$MetricDaoMixin {
  MetricDao(super.db);

  Future<void> batchUpsertMetrics(
    List<HealthMetricsTableCompanion> points,
  ) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(healthMetricsTable, points);
    });
  }

  Future<void> cleanupLegacyHealthConnectDuplicates() async {
    await customStatement(
      "DELETE FROM health_metrics_table WHERE source = 'health_connect' AND id NOT GLOB 'hc-*-????-??-??';",
    );
  }

  Future<List<HealthMetricsTableData>> getMetricsSince(DateTime since) {
    return (select(healthMetricsTable)
          ..where((tbl) => tbl.syncedAt.isBiggerThanValue(since))
          ..orderBy([(t) => OrderingTerm(expression: t.syncedAt)]))
        .get();
  }

  Future<List<HealthMetricsTableData>> getUnsyncedMetrics() {
    return (select(
      healthMetricsTable,
    )..where((tbl) => tbl.isSynced.equals(false))).get();
  }

  Future<void> markAsSynced(List<String> ids) {
    return (update(healthMetricsTable)..where((tbl) => tbl.id.isIn(ids))).write(
      const HealthMetricsTableCompanion(isSynced: Value(true)),
    );
  }

  Stream<List<HealthMetricsTableData>> watchMetricsForRange(
    String metric,
    DateTime from,
    DateTime to,
  ) {
    return (select(healthMetricsTable)
          ..where(
            (tbl) =>
                tbl.metric.equals(metric) &
                tbl.startTime.isBiggerOrEqualValue(from) &
                tbl.endTime.isSmallerOrEqualValue(to),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.startTime)]))
        .watch();
  }

  Future<List<HealthMetricsTableData>> getMetricsForRange(
    String metric,
    DateTime from,
    DateTime to,
  ) {
    return (select(healthMetricsTable)
          ..where(
            (tbl) =>
                tbl.metric.equals(metric) &
                tbl.startTime.isBiggerOrEqualValue(from) &
                tbl.endTime.isSmallerOrEqualValue(to),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.startTime)]))
        .get();
  }

  Future<Map<String, double>> getDailySummary(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final points =
        await (select(healthMetricsTable)
              ..where(
                (tbl) =>
                    tbl.startTime.isBiggerOrEqualValue(startOfDay) &
                    tbl.startTime.isSmallerThanValue(endOfDay),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.startTime)]))
            .get();

    final summary = <String, double>{};
    for (final pt in points) {
      if (pt.metric == 'WEIGHT' || pt.metric == 'BODY_FAT') {
        summary[pt.metric] = pt.value;
      } else if (pt.id.startsWith('hc-')) {
        summary[pt.metric] = pt.value;
      } else {
        summary[pt.metric] = (summary[pt.metric] ?? 0.0) + pt.value;
      }
    }
    return summary;
  }
}
