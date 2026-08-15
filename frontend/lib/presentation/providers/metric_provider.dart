import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/native/health_connect_channel.dart';
import '../../data/repositories/offline_metric_repository.dart';
import 'routine_provider.dart';

final offlineMetricRepositoryProvider = Provider<OfflineMetricRepository>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  final client = ref.watch(apiClientProvider);
  return OfflineMetricRepository(db: db, apiClient: client);
});

final healthConnectStatusProvider =
    FutureProvider.autoDispose<bool>((ref) async {
      final isAvail = await HealthConnectChannel.isAvailable();
      if (!isAvail) return false;
      return HealthConnectChannel.hasPermissions();
    });

final dailyMetricSummaryProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
      final repo = ref.watch(offlineMetricRepositoryProvider);
      final dateStr = ref.watch(selectedDateProvider);
      final date = DateTime.tryParse(dateStr) ?? DateTime.now();

      // On Android, attempt to read fresh aggregates from Health Connect first if permissions granted
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
