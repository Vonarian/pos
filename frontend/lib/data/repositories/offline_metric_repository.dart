import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import '../remote/api_client.dart';
import '../../domain/models/health_data_point.dart';

class OfflineMetricRepository {
  final AppDatabase db;
  final ApiClient? apiClient;

  OfflineMetricRepository({required this.db, this.apiClient});

  Future<void> ingestMetrics(List<HealthDataPoint> points) async {
    final companions = points
        .map(
          (p) => HealthMetricsTableCompanion.insert(
            id: p.id,
            source: p.source,
            metric: p.metric.value,
            value: p.value,
            unit: p.unit,
            startTime: p.startTime,
            endTime: p.endTime,
            externalId: Value(p.externalId),
            syncedAt: p.syncedAt,
            isSynced: const Value(false),
          ),
        )
        .toList();

    await db.metricDao.cleanupLegacyHealthConnectDuplicates();
    await db.metricDao.batchUpsertMetrics(companions);

    // Sync to backend if online
    if (apiClient != null) {
      try {
        await apiClient!.pushSync(routines: [], metrics: points);
        await db.metricDao.markAsSynced(points.map((e) => e.id).toList());
      } catch (_) {}
    }
  }

  Future<void> logManualMetric({
    required MetricType metric,
    required double value,
    required String unit,
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final point = HealthDataPoint(
      id: 'manual-${metric.value.toLowerCase()}-$dateStr-${const Uuid().v4().substring(0, 8)}',
      source: 'manual',
      metric: metric,
      value: value,
      unit: unit,
      startTime: now,
      endTime: now,
      syncedAt: now,
    );

    await ingestMetrics([point]);
  }

  Future<List<HealthDataPoint>> getMetricSeries(
    MetricType metric,
    DateTime from,
    DateTime to,
  ) async {
    final localData = await db.metricDao.getMetricsForRange(
      metric.value,
      from,
      to,
    );

    return localData
        .map(
          (e) => HealthDataPoint(
            id: e.id,
            source: e.source,
            metric: MetricType.fromString(e.metric),
            value: e.value,
            unit: e.unit,
            startTime: e.startTime,
            endTime: e.endTime,
            externalId: e.externalId,
            syncedAt: e.syncedAt,
          ),
        )
        .toList();
  }

  Future<Map<String, double>> getDailySummary(DateTime date) async {
    // Local SQLite aggregation first
    final localSummary = await db.metricDao.getDailySummary(date);
    if (localSummary.isNotEmpty) {
      return localSummary;
    }

    // Fallback to backend summary (Desktop fallback)
    if (apiClient != null) {
      try {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final remote = await apiClient!.getDailySummary(dateStr);
        return {
          'STEPS': (remote['steps'] as num?)?.toDouble() ?? 0.0,
          'CALORIES_BURNED':
              (remote['calories_burned'] as num?)?.toDouble() ?? 0.0,
          'SLEEP_DURATION':
              (remote['sleep_minutes'] as num?)?.toDouble() ?? 0.0,
          'WEIGHT': (remote['weight_kg'] as num?)?.toDouble() ?? 0.0,
        };
      } catch (_) {}
    }

    return localSummary;
  }
}
