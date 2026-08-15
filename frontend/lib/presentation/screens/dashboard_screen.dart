import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/routine_item.dart';
import '../providers/routine_provider.dart';
import '../providers/metric_provider.dart';
import '../widgets/quadrant_card.dart';
import '../widgets/metric_summary_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quadrantState = ref.watch(quadrantStateProvider);
    final metricsAsync = ref.watch(dailyMetricSummaryProvider);
    final repo = ref.watch(offlineRoutineRepositoryProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    final isToday =
        selectedDate == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary
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
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync now',
            onPressed: () async {
              await repo.syncWithServer();
              ref.invalidate(routinesStreamProvider);
              ref.invalidate(dailyMetricSummaryProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Synchronized with Go backend')),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await repo.syncWithServer();
          ref.invalidate(routinesStreamProvider);
          ref.invalidate(dailyMetricSummaryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Date Navigation Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () {
                    final curr = DateTime.parse(selectedDate);
                    final prev = curr.subtract(const Duration(days: 1));
                    ref
                        .read(selectedDateProvider.notifier)
                        .setDate(DateFormat('yyyy-MM-dd').format(prev));
                  },
                ),
                Text(
                  isToday
                      ? "Today (${DateFormat('MMM d').format(DateTime.parse(selectedDate))})"
                      : DateFormat('EEEE, MMM d')
                            .format(DateTime.parse(selectedDate)),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () {
                    final curr = DateTime.parse(selectedDate);
                    final next = curr.add(const Duration(days: 1));
                    ref
                        .read(selectedDateProvider.notifier)
                        .setDate(DateFormat('yyyy-MM-dd').format(next));
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Adherence summary banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Adherence',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${(quadrantState.adherenceRate * 100).toInt()}% Done (${quadrantState.completedCount}/${quadrantState.totalCount})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(
                      value: quadrantState.adherenceRate,
                      strokeWidth: 4,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 4 Quadrants
            QuadrantCard(
              title: 'Morning Protocol',
              timeRange: '06:00 – 12:00',
              icon: Icons.wb_sunny_rounded,
              isActive:
                  isToday && quadrantState.activeWindow == TimeWindow.morning,
              items: quadrantState.morning,
              onComplete: (id) => repo.completeRoutine(id),
              onSkip: (id) => repo.skipRoutine(id),
              onDefer: (id) => repo.deferRoutine(id),
            ),

            QuadrantCard(
              title: 'Mid-Day & Pre-Workout',
              timeRange: '12:00 – 18:00',
              icon: Icons.fitness_center_rounded,
              isActive:
                  isToday && quadrantState.activeWindow == TimeWindow.afternoon,
              items: quadrantState.afternoon,
              onComplete: (id) => repo.completeRoutine(id),
              onSkip: (id) => repo.skipRoutine(id),
              onDefer: (id) => repo.deferRoutine(id),
            ),

            QuadrantCard(
              title: 'Evening & Post-Workout',
              timeRange: '18:00 – 21:00',
              icon: Icons.restaurant_rounded,
              isActive:
                  isToday && quadrantState.activeWindow == TimeWindow.evening,
              items: quadrantState.evening,
              onComplete: (id) => repo.completeRoutine(id),
              onSkip: (id) => repo.skipRoutine(id),
              onDefer: (id) => repo.deferRoutine(id),
            ),

            QuadrantCard(
              title: 'Night / Bedtime Stack',
              timeRange: '21:00 – 23:59',
              icon: Icons.nights_stay_rounded,
              isActive:
                  isToday && quadrantState.activeWindow == TimeWindow.night,
              items: quadrantState.night,
              onComplete: (id) => repo.completeRoutine(id),
              onSkip: (id) => repo.skipRoutine(id),
              onDefer: (id) => repo.deferRoutine(id),
            ),

            const SizedBox(height: 12),

            // Metrics Telemetry
            metricsAsync.when(
              data: (metrics) => MetricSummaryChart(metrics: metrics),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Habit'),
        onPressed: () => _showAddRoutineDialog(context, ref, selectedDate),
      ),
    );
  }

  void _showAddRoutineDialog(BuildContext context, WidgetRef ref, String date) {
    final titleController = TextEditingController();
    final dosageController = TextEditingController();
    String category = 'MEDS';
    TimeWindow window = TimeWindow.morning;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Daily Habit / Medication',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Habit Title',
                      hintText: 'e.g. Creatine 5g, Zone 2 Cardio',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage / Notes (Optional)',
                      hintText: 'e.g. 5g with water, NFC shelf',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: category,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'MEDS',
                              child: Text('Meds/Supps'),
                            ),
                            DropdownMenuItem(
                              value: 'WORKOUT',
                              child: Text('Workout'),
                            ),
                            DropdownMenuItem(
                              value: 'NUTRITION',
                              child: Text('Nutrition'),
                            ),
                            DropdownMenuItem(
                              value: 'HABIT',
                              child: Text('Habit'),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => category = val ?? 'MEDS'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<TimeWindow>(
                          initialValue: window,
                          decoration: const InputDecoration(
                            labelText: 'Time Window',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: TimeWindow.morning,
                              child: Text('Morning'),
                            ),
                            DropdownMenuItem(
                              value: TimeWindow.afternoon,
                              child: Text('Mid-Day'),
                            ),
                            DropdownMenuItem(
                              value: TimeWindow.evening,
                              child: Text('Evening'),
                            ),
                            DropdownMenuItem(
                              value: TimeWindow.night,
                              child: Text('Night'),
                            ),
                          ],
                          onChanged: (val) => setState(
                            () => window = val ?? TimeWindow.morning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;
                        final repo = ref.read(offlineRoutineRepositoryProvider);
                        final now = DateTime.now();
                        final item = RoutineItem(
                          id: const Uuid().v4(),
                          title: titleController.text.trim(),
                          category: category,
                          timeWindow: window,
                          scheduledDate: date,
                          status: ItemStatus.pending,
                          metadata: dosageController.text.isNotEmpty
                              ? {'dosage': dosageController.text.trim()}
                              : {},
                          updatedAt: now,
                          createdAt: now,
                        );
                        await repo.createRoutine(item);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text(
                        'Save Ticket',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
