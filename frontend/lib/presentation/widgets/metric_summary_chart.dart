import 'package:flutter/material.dart';

import '../../domain/models/health_data_point.dart';
import 'metric_telemetry_card.dart';

class MetricSummaryChart extends StatelessWidget {
  final Map<String, double> metrics;
  final bool isConnected;
  final VoidCallback? onConnect;
  final VoidCallback? onRefresh;
  final Function(MetricType metric)? onMetricTap;

  const MetricSummaryChart({
    super.key,
    required this.metrics,
    this.isConnected = true,
    this.onConnect,
    this.onRefresh,
    this.onMetricTap,
  });

  String _formatSleep(double minutes) {
    if (minutes <= 0) return "0m";
    final totalMin = minutes.round();
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    if (h == 0) return "${m}m";
    if (m == 0) return "${h}h";
    return "${h}h ${m}m";
  }

  Widget _buildConnectBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.health_and_safety_rounded, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Sync steps, food, calories & sleep passively',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ),
          FilledButton.tonal(
            onPressed: onConnect,
            child: const Text('Grant Access', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Health Telemetry',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRefresh != null && isConnected) ...[
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF94A3B8)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Refresh Health Connect',
                onPressed: onRefresh,
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              isConnected ? Icons.check_circle_outline_rounded : Icons.sync_problem_rounded,
              size: 14,
              color: isConnected ? Colors.tealAccent : Colors.amberAccent,
            ),
            const SizedBox(width: 4),
            Text(
              isConnected ? 'Health Connect' : 'Not Connected',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isConnected ? const Color(0xFF94A3B8) : Colors.amberAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(Map<String, double> metrics) {
    final steps = metrics['STEPS'] ?? 0.0;
    final food = metrics['CALORIES_CONSUMED'] ?? 0.0;
    final burned = metrics['CALORIES_BURNED'] ?? 0.0;
    final sleepMin = metrics['SLEEP_DURATION'] ?? 0.0;
    final weight = metrics['WEIGHT'] ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricTelemetryCard(
                label: 'Steps',
                value: steps.round().toString(),
                target: '10,000',
                progress: (steps / 10000.0).clamp(0.0, 1.0),
                icon: Icons.directions_walk_rounded,
                color: Colors.cyanAccent.shade400,
                onTap: onMetricTap != null ? () => onMetricTap!(MetricType.steps) : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetricTelemetryCard(
                label: 'Sleep',
                value: _formatSleep(sleepMin),
                target: '8h 0m',
                progress: (sleepMin / 480.0).clamp(0.0, 1.0),
                icon: Icons.bedtime_rounded,
                color: Colors.purpleAccent.shade100,
                onTap: onMetricTap != null ? () => onMetricTap!(MetricType.sleepDuration) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: MetricTelemetryCard(
                label: 'Food (In)',
                value: "${food.round()} kcal",
                target: '2,400',
                progress: (food / 2400.0).clamp(0.0, 1.0),
                icon: Icons.restaurant_rounded,
                color: Colors.amberAccent.shade400,
                onTap: onMetricTap != null ? () => onMetricTap!(MetricType.caloriesConsumed) : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetricTelemetryCard(
                label: 'Burned (Out)',
                value: "${burned.round()} kcal",
                target: '500',
                progress: (burned / 500.0).clamp(0.0, 1.0),
                icon: Icons.local_fire_department_rounded,
                color: Colors.deepOrangeAccent.shade200,
                onTap: onMetricTap != null ? () => onMetricTap!(MetricType.caloriesBurned) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: MetricTelemetryCard(
                label: 'Weight',
                value: weight > 0 ? "${weight.toStringAsFixed(1)} kg" : "--",
                target: 'Target',
                progress: 1.0,
                icon: Icons.monitor_weight_rounded,
                color: Colors.tealAccent.shade400,
                onTap: onMetricTap != null ? () => onMetricTap!(MetricType.weight) : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        if (!isConnected && onConnect != null) ...[
          _buildConnectBanner(context),
          const SizedBox(height: 12),
        ],
        _buildMetricsGrid(metrics),
      ],
    );
  }
}
