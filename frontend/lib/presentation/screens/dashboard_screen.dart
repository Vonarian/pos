import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/native/health_connect_channel.dart';
import '../../data/repositories/offline_routine_repository.dart';
import '../../domain/models/routine_item.dart';
import '../providers/metric_provider.dart';
import '../providers/routine_provider.dart';
import '../widgets/add_routine_sheet.dart';
import '../widgets/dashboard_adherence_banner.dart';
import '../widgets/dashboard_date_nav_bar.dart';
import '../widgets/metric_summary_chart.dart';
import '../widgets/quadrant_card.dart';
import '../widgets/sync_app_bar_button.dart';
import '../widgets/window_settings_sheet.dart';
import 'home_shell.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  AppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'POS',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded, size: 20),
          tooltip: 'Window & Reminder Settings',
          onPressed: () {
            WindowSettingsSheet.show(
              context,
              settings: ref.read(windowSettingsProvider),
              onSave: (s) =>
                  ref.read(windowSettingsProvider.notifier).updateSettings(s),
            );
          },
        ),
        const SyncAppBarButton(),
      ],
    );
  }

  Widget _buildQuadrant(
    OfflineRoutineRepository repo,
    String title,
    String timeRange,
    IconData icon,
    TimeWindow window,
    bool isToday,
    QuadrantState state,
    List<RoutineItem> items,
  ) {
    return QuadrantCard(
      title: title,
      timeRange: timeRange,
      icon: icon,
      isActive: isToday && state.activeWindow == window,
      items: items,
      onComplete: (id) => repo.completeRoutine(id),
      onRevert: (id) => repo.revertRoutine(id),
      onSkip: (id) => repo.skipRoutine(id),
      onDefer: (id) => repo.deferRoutine(id),
      onDelete: (id) => repo.deleteRoutine(id),
    );
  }

  Widget _buildMetricsSection(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dailyMetricSummaryProvider);
    return metricsAsync.when(
      data: (metrics) => MetricSummaryChart(
        metrics: metrics,
        isConnected:
            ref.watch(healthConnectStatusProvider).value ?? false,
        onConnect: () async {
          final granted = await HealthConnectChannel.requestPermissions();
          if (granted) {
            ref.invalidate(healthConnectStatusProvider);
            ref.invalidate(dailyMetricSummaryProvider);
          }
        },
        onRefresh: () => ref.invalidate(dailyMetricSummaryProvider),
        onMetricTap: (metric) {
          ref.read(selectedMetricTypeProvider.notifier).select(metric);
          ref.read(currentTabProvider.notifier).select(1);
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => const SizedBox.shrink(),
    );
  }

  List<Widget> _buildContentList(
    BuildContext context,
    WidgetRef ref,
    OfflineRoutineRepository repo,
    QuadrantState state,
    String selectedDate,
    bool isToday,
  ) {
    return [
      DashboardDateNavBar(ref: ref, date: selectedDate, isToday: isToday),
      const SizedBox(height: 12),
      DashboardAdherenceBanner(state: state),
      const SizedBox(height: 18),
      _buildQuadrant(repo, 'Morning Protocol', '06:00 – 12:00', Icons.wb_sunny_rounded, TimeWindow.morning, isToday, state, state.morning),
      _buildQuadrant(repo, 'Mid-Day & Pre-Workout', '12:00 – 18:00', Icons.fitness_center_rounded, TimeWindow.afternoon, isToday, state, state.afternoon),
      _buildQuadrant(repo, 'Evening & Post-Workout', '18:00 – 21:00', Icons.restaurant_rounded, TimeWindow.evening, isToday, state, state.evening),
      _buildQuadrant(repo, 'Night / Bedtime Stack', '21:00 – 23:59', Icons.nights_stay_rounded, TimeWindow.night, isToday, state, state.night),
      const SizedBox(height: 12),
      _buildMetricsSection(context, ref),
      const SizedBox(height: 40),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quadrantState = ref.watch(quadrantStateProvider);
    final repo = ref.watch(offlineRoutineRepositoryProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final isToday =
        selectedDate == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: _buildAppBar(context, ref),
      body: RefreshIndicator(
        onRefresh: () async {
          await repo.syncWithServer();
          ref.invalidate(routinesStreamProvider);
          ref.invalidate(dailyMetricSummaryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: _buildContentList(
            context,
            ref,
            repo,
            quadrantState,
            selectedDate,
            isToday,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Habit'),
        onPressed: () => AddRoutineSheet.show(context, ref, selectedDate),
      ),
    );
  }
}
