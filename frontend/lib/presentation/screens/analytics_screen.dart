import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/health_data_point.dart';
import '../providers/metric_provider.dart';
import '../widgets/analytics_chart_card.dart';
import '../widgets/log_metric_modal.dart';
import '../widgets/metric_tab_pill.dart';
import '../widgets/quick_log_banner.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMetric = ref.watch(selectedMetricTypeProvider);
    final selectedDays = ref.watch(rangeDaysProvider);
    final seriesAsync = ref.watch(metricSeriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Refresh Metrics',
            onPressed: () {
              ref.invalidate(metricSeriesProvider);
              ref.invalidate(dailyMetricSummaryProvider);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildTimeHorizon(ref, selectedDays),
          const SizedBox(height: 14),
          _buildMetricPills(ref, selectedMetric),
          const SizedBox(height: 16),
          _buildChartArea(seriesAsync, selectedMetric, selectedDays),
          const SizedBox(height: 20),
          QuickLogBanner(
            onLogTap: () => _showLogMetricSheet(context, ref, selectedMetric),
          ),
          const SizedBox(height: 30),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text('Log Metric'),
        onPressed: () => _showLogMetricSheet(context, ref, selectedMetric),
      ),
    );
  }

  Widget _buildTimeHorizon(WidgetRef ref, int selectedDays) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Time Horizon',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 7, label: Text('7D')),
            ButtonSegment(value: 14, label: Text('14D')),
            ButtonSegment(value: 30, label: Text('30D')),
          ],
          selected: {selectedDays},
          onSelectionChanged: (set) {
            if (set.isNotEmpty) {
              ref.read(rangeDaysProvider.notifier).select(set.first);
            }
          },
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricPills(WidgetRef ref, MetricType selectedMetric) {
    const tabs = [
      (
        MetricType.steps,
        'Steps',
        Icons.directions_walk_rounded,
        Color(0xFF22D3EE),
      ),
      (
        MetricType.caloriesConsumed,
        'Food',
        Icons.restaurant_rounded,
        Color(0xFFFBBF24),
      ),
      (
        MetricType.caloriesBurned,
        'Burned',
        Icons.local_fire_department_rounded,
        Color(0xFFFF7043),
      ),
      (
        MetricType.sleepDuration,
        'Sleep',
        Icons.bedtime_rounded,
        Color(0xFFE879F9),
      ),
      (
        MetricType.weight,
        'Weight',
        Icons.monitor_weight_rounded,
        Color(0xFF2DD4BF),
      ),
      (
        MetricType.waterIntake,
        'Water',
        Icons.water_drop_rounded,
        Color(0xFF38BDF8),
      ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs
            .map(
              (t) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: MetricTabPill(
                  label: t.$2,
                  icon: t.$3,
                  color: t.$4,
                  isSelected: selectedMetric == t.$1,
                  onTap: () => ref
                      .read(selectedMetricTypeProvider.notifier)
                      .select(t.$1),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildChartArea(
    AsyncValue<List<HealthDataPoint>> seriesAsync,
    MetricType selectedMetric,
    int selectedDays,
  ) {
    return seriesAsync.when(
      data: (points) => AnalyticsChartCard(
        metric: selectedMetric,
        days: selectedDays,
        points: points,
      ),
      loading: () => Container(
        height: 280,
        decoration: BoxDecoration(
          color: const Color(0xFF141C2B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Container(
        height: 280,
        decoration: BoxDecoration(
          color: const Color(0xFF141C2B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Error loading metrics: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  void _showLogMetricSheet(
    BuildContext context,
    WidgetRef ref,
    MetricType initialMetric,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141C2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => LogMetricModal(initialMetric: initialMetric),
    );
  }
}
