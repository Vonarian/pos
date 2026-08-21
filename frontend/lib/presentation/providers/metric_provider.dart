import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/native/health_connect_channel.dart';
import '../../data/repositories/offline_metric_repository.dart';
import '../../domain/models/health_data_point.dart';
import 'routine_provider.dart';

final offlineMetricRepositoryProvider = Provider<OfflineMetricRepository>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  final client = ref.watch(apiClientProvider);
  return OfflineMetricRepository(db: db, apiClient: client);
});

final healthConnectStatusProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final isAvail = await HealthConnectChannel.isAvailable();
  if (!isAvail) return false;
  return HealthConnectChannel.hasPermissions();
});

class SelectedMetricNotifier extends Notifier<MetricType> {
  @override
  MetricType build() => MetricType.steps;
  void select(MetricType type) => state = type;
}

final selectedMetricTypeProvider =
    NotifierProvider<SelectedMetricNotifier, MetricType>(
      SelectedMetricNotifier.new,
    );

class RangeDaysNotifier extends Notifier<int> {
  @override
  int build() => 7;
  void select(int days) => state = days;
}

final rangeDaysProvider = NotifierProvider<RangeDaysNotifier, int>(
  RangeDaysNotifier.new,
);

final metricSeriesProvider = FutureProvider.autoDispose<List<HealthDataPoint>>((
  ref,
) async {
  final repo = ref.watch(offlineMetricRepositoryProvider);
  final metric = ref.watch(selectedMetricTypeProvider);
  final days = ref.watch(rangeDaysProvider);
  final now = DateTime.now();
  final to = DateTime(now.year, now.month, now.day, 23, 59, 59);
  final from = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: days - 1));

  try {
    if (await HealthConnectChannel.isAvailable() &&
        await HealthConnectChannel.hasPermissions()) {
      final points = await HealthConnectChannel.getHealthHistory(days: days);
      if (points.isNotEmpty) {
        await repo.ingestMetrics(points);
      }
    }
  } catch (_) {}

  return repo.getMetricSeries(metric, from, to);
});

final dailyMetricSummaryProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
      final repo = ref.watch(offlineMetricRepositoryProvider);
      final dateStr = ref.watch(selectedDateProvider);
      final date = DateTime.tryParse(dateStr) ?? DateTime.now();

      try {
        if (await HealthConnectChannel.isAvailable() &&
            await HealthConnectChannel.hasPermissions()) {
          final points = await HealthConnectChannel.getTodayAggregates();
          if (points.isNotEmpty) {
            await repo.ingestMetrics(points);
          }
        }
      } catch (_) {}

      return repo.getDailySummary(date);
    });
