import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/models/health_data_point.dart';
import 'analytics_chart_builder.dart';
import 'analytics_stat_row.dart';

class AnalyticsChartCard extends StatelessWidget {
  final MetricType metric;
  final int days;
  final List<HealthDataPoint> points;

  const AnalyticsChartCard({
    super.key,
    required this.metric,
    required this.days,
    required this.points,
  });

  Color _getMetricColor() {
    switch (metric) {
      case MetricType.steps:
        return Colors.cyanAccent.shade400;
      case MetricType.caloriesConsumed:
        return Colors.amberAccent.shade400;
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
      if (val <= 0) return "0m";
      final totalMin = val.round();
      final h = totalMin ~/ 60;
      final m = totalMin % 60;
      return h == 0 ? "${m}m" : (m == 0 ? "${h}h" : "${h}h ${m}m");
    }
    if (metric == MetricType.weight) return "${val.toStringAsFixed(1)} kg";
    if (metric == MetricType.steps) return val.round().toString();
    if (metric == MetricType.caloriesConsumed ||
        metric == MetricType.caloriesBurned) {
      return "${val.round()} kcal";
    }
    if (metric == MetricType.waterIntake) return "${val.round()} ml";
    return val.toStringAsFixed(1);
  }

  Widget _buildLineChart(
    List<FlSpot> spots,
    double maxVal,
    List<MapEntry<DateTime, double>> entries,
  ) {
    final color = _getMetricColor();
    if (spots.isEmpty || maxVal == 0) {
      return Center(
        child: Text(
          'No entries recorded for this $days-day window',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
      );
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touched) => touched
                .map(
                  (s) => LineTooltipItem(
                    _formatValue(s.y),
                    const TextStyle(
                      color: Color(0xFFF8FAFC),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: Color(0xFF1E293B), strokeWidth: 1),
        ),
        titlesData: AnalyticsChartBuilder.buildTitlesData(days, entries),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (days - 1).toDouble(),
        minY: 0,
        maxY: maxVal * 1.25,
        lineBarsData: [AnalyticsChartBuilder.buildBarData(days, spots, color)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dailyValues = <DateTime, double>{};
    for (int i = days - 1; i >= 0; i--) {
      dailyValues[DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: i))] =
          0.0;
    }
    for (final p in points) {
      final pDate = DateTime(
        p.startTime.year,
        p.startTime.month,
        p.startTime.day,
      );
      if (dailyValues.containsKey(pDate)) {
        if (metric == MetricType.weight || p.source == 'health_connect') {
          dailyValues[pDate] = p.value;
        } else {
          dailyValues[pDate] = (dailyValues[pDate] ?? 0.0) + p.value;
        }
      }
    }

    final entries = dailyValues.entries.toList();
    final spots = <FlSpot>[];
    double sum = 0.0, maxVal = 0.0;
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

    final latestVal = entries.isNotEmpty ? entries.last.value : 0.0;
    final avg = countNonZero == 0 ? 0.0 : sum / countNonZero;

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
          AnalyticsStatRow(
            latestVal: _formatValue(latestVal),
            avg: _formatValue(avg),
            peak: _formatValue(maxVal),
            avgColor: _getMetricColor(),
          ),
          const SizedBox(height: 24),
          SizedBox(height: 190, child: _buildLineChart(spots, maxVal, entries)),
        ],
      ),
    );
  }
}
