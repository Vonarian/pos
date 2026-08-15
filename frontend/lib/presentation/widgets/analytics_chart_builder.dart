import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnalyticsChartBuilder {
  static FlTitlesData buildTitlesData(
    int days,
    List<MapEntry<DateTime, double>> entries,
  ) {
    return FlTitlesData(
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
              return Text(
                DateFormat('M/d').format(entries[idx].key),
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  static LineChartBarData buildBarData(
    int days,
    List<FlSpot> spots,
    Color color,
  ) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: days <= 14,
        getDotPainter:
            (spot, percent, barData, index) => FlDotCirclePainter(
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
    );
  }
}
