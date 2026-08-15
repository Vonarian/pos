import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models/health_data_point.dart';
import '../providers/metric_provider.dart';

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
          // Range Filter (7D / 14D / 30D)
          Row(
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
          ),

          const SizedBox(height: 14),

          // Metric Category Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _MetricTabPill(
                  label: 'Steps',
                  icon: Icons.directions_walk_rounded,
                  color: Colors.cyanAccent.shade400,
                  isSelected: selectedMetric == MetricType.steps,
                  onTap: () => ref
                      .read(selectedMetricTypeProvider.notifier)
                      .select(MetricType.steps),
                ),
                const SizedBox(width: 8),
                _MetricTabPill(
                  label: 'Calories',
                  icon: Icons.local_fire_department_rounded,
                  color: Colors.deepOrangeAccent.shade200,
                  isSelected: selectedMetric == MetricType.caloriesBurned,
                  onTap: () => ref
                      .read(selectedMetricTypeProvider.notifier)
                      .select(MetricType.caloriesBurned),
                ),
                const SizedBox(width: 8),
                _MetricTabPill(
                  label: 'Sleep',
                  icon: Icons.bedtime_rounded,
                  color: Colors.purpleAccent.shade100,
                  isSelected: selectedMetric == MetricType.sleepDuration,
                  onTap: () => ref
                      .read(selectedMetricTypeProvider.notifier)
                      .select(MetricType.sleepDuration),
                ),
                const SizedBox(width: 8),
                _MetricTabPill(
                  label: 'Weight',
                  icon: Icons.monitor_weight_rounded,
                  color: Colors.tealAccent.shade400,
                  isSelected: selectedMetric == MetricType.weight,
                  onTap: () => ref
                      .read(selectedMetricTypeProvider.notifier)
                      .select(MetricType.weight),
                ),
                const SizedBox(width: 8),
                _MetricTabPill(
                  label: 'Water',
                  icon: Icons.water_drop_rounded,
                  color: Colors.lightBlueAccent,
                  isSelected: selectedMetric == MetricType.waterIntake,
                  onTap: () => ref
                      .read(selectedMetricTypeProvider.notifier)
                      .select(MetricType.waterIntake),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Chart & Stats Card
          seriesAsync.when(
            data: (points) => _AnalyticsChartCard(
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
          ),

          const SizedBox(height: 20),

          // Quick Action Banner
          _QuickLogBanner(
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
      builder: (ctx) => _LogMetricModal(initialMetric: initialMetric),
    );
  }
}

class _MetricTabPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _MetricTabPill({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.18)
                : const Color(0xFF141C2B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : const Color(0xFF1E293B),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : const Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFFF8FAFC) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsChartCard extends StatelessWidget {
  final MetricType metric;
  final int days;
  final List<HealthDataPoint> points;

  const _AnalyticsChartCard({
    required this.metric,
    required this.days,
    required this.points,
  });

  Color _getMetricColor() {
    switch (metric) {
      case MetricType.steps:
        return Colors.cyanAccent.shade400;
      case MetricType.caloriesBurned:
        return Colors.deepOrangeAccent.shade200;
      case MetricType.sleepDuration:
        return Colors.purpleAccent.shade100;
      case MetricType.weight:
        return Colors.tealAccent.shade400;
      case MetricType.waterIntake:
        return Colors.lightBlueAccent;
      default:
        return Colors.indigoAccent;
    }
  }

  String _formatValue(double val) {
    if (metric == MetricType.sleepDuration) {
      return "${(val / 60.0).toStringAsFixed(1)}h";
    }
    if (metric == MetricType.weight) {
      return "${val.toStringAsFixed(1)} kg";
    }
    if (metric == MetricType.steps) {
      return val.toInt().toString();
    }
    if (metric == MetricType.caloriesBurned) {
      return "${val.toInt()} kcal";
    }
    if (metric == MetricType.waterIntake) {
      return "${val.toInt()} ml";
    }
    return val.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getMetricColor();

    // Group values per day
    final now = DateTime.now();
    final dailyValues = <DateTime, double>{};
    for (int i = days - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      dailyValues[d] = 0.0;
    }

    for (final p in points) {
      final pDate = DateTime(p.startTime.year, p.startTime.month, p.startTime.day);
      if (dailyValues.containsKey(pDate)) {
        if (metric == MetricType.weight) {
          dailyValues[pDate] = p.value;
        } else {
          dailyValues[pDate] = (dailyValues[pDate] ?? 0.0) + p.value;
        }
      }
    }

    final entries = dailyValues.entries.toList();
    final spots = <FlSpot>[];
    double sum = 0.0;
    double maxVal = 0.0;
    int countNonZero = 0;

    for (int i = 0; i < entries.length; i++) {
      final val = entries[i].value;
      spots.add(FlSpot(i.toDouble(), val));
      if (val > 0) {
        sum += val;
        countNonZero++;
      }
      if (val > maxVal) maxVal = val;
    }

    final avg = countNonZero == 0 ? 0.0 : sum / countNonZero;
    final latestVal = entries.isNotEmpty ? entries.last.value : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Highlights
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatValue(latestVal),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF8FAFC),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Average',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatValue(avg),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Peak',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatValue(maxVal),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF8FAFC),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Chart
          SizedBox(
            height: 190,
            child: spots.isEmpty || maxVal == 0
                ? Center(
                    child: Text(
                      'No entries recorded for this $days-day window',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: const Color(0xFF1E293B),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: (days / 6).clamp(1.0, 10.0),
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < entries.length) {
                                final date = entries[idx].key;
                                return Text(
                                  DateFormat('M/d').format(date),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (days - 1).toDouble(),
                      minY: 0,
                      maxY: maxVal * 1.25,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: color,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: days <= 14,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 3.5,
                              color: color,
                              strokeWidth: 1.5,
                              strokeColor: const Color(0xFF141C2B),
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color.withValues(alpha: 0.35),
                                color.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuickLogBanner extends StatelessWidget {
  final VoidCallback onLogTap;

  const _QuickLogBanner({required this.onLogTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit_calendar_rounded,
              color: Colors.blueAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manual Entry',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF8FAFC),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Log weight, water intake, or custom metrics',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: onLogTap,
            child: const Text('Add Entry'),
          ),
        ],
      ),
    );
  }
}

class _LogMetricModal extends ConsumerStatefulWidget {
  final MetricType initialMetric;

  const _LogMetricModal({required this.initialMetric});

  @override
  ConsumerState<_LogMetricModal> createState() => _LogMetricModalState();
}

class _LogMetricModalState extends ConsumerState<_LogMetricModal> {
  late MetricType _selectedMetric;
  final _valueController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedMetric = widget.initialMetric;
  }

  String _getUnit() {
    switch (_selectedMetric) {
      case MetricType.steps:
        return 'count';
      case MetricType.caloriesBurned:
        return 'kcal';
      case MetricType.sleepDuration:
        return 'minutes';
      case MetricType.weight:
        return 'kg';
      case MetricType.waterIntake:
        return 'ml';
      default:
        return 'units';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Log Health Metric',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF8FAFC),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metric dropdown
          DropdownButtonFormField<MetricType>(
            initialValue: _selectedMetric,
            decoration: InputDecoration(
              labelText: 'Metric Type',
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E293B)),
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: MetricType.weight,
                child: Text('⚖️ Weight (kg)'),
              ),
              const DropdownMenuItem(
                value: MetricType.waterIntake,
                child: Text('💧 Water Intake (ml)'),
              ),
              const DropdownMenuItem(
                value: MetricType.sleepDuration,
                child: Text('😴 Sleep (minutes)'),
              ),
              const DropdownMenuItem(
                value: MetricType.steps,
                child: Text('🚶 Steps (count)'),
              ),
              const DropdownMenuItem(
                value: MetricType.caloriesBurned,
                child: Text('🔥 Active Calories (kcal)'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedMetric = val);
            },
          ),

          const SizedBox(height: 14),

          // Value input
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Value (${_getUnit()})',
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E293B)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSaving ? null : _saveMetric,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Entry', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMetric() async {
    final text = _valueController.text.trim();
    final val = double.tryParse(text);
    if (val == null || val <= 0) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(offlineMetricRepositoryProvider);
      await repo.logManualMetric(
        metric: _selectedMetric,
        value: val,
        unit: _getUnit(),
      );

      ref.invalidate(metricSeriesProvider);
      ref.invalidate(dailyMetricSummaryProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged ${val.toString()} ${_getUnit()} successfully'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
