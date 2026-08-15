import 'package:flutter/material.dart';

import '../../domain/models/health_data_point.dart';

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

  @override
  Widget build(BuildContext context) {
    final steps = metrics['STEPS'] ?? 0.0;
    final calories = metrics['CALORIES_BURNED'] ?? 0.0;
    final sleepMin = metrics['SLEEP_DURATION'] ?? 0.0;
    final weight = metrics['WEIGHT'] ?? 0.0;

    final sleepHours = (sleepMin / 60.0).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'Health Telemetry',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF8FAFC),
                ),
              ),
            ),
            const SizedBox(width: 8),
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
        ),
        const SizedBox(height: 12),

        if (!isConnected && onConnect != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141C2B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.health_and_safety_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Connect Health Connect',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF8FAFC),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sync steps, calories, sleep & weight passively',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: onConnect,
                  child: const Text('Grant Access', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Steps',
                value: steps.toInt().toString(),
                target: '10,000',
                progress: (steps / 10000.0).clamp(0.0, 1.0),
                icon: Icons.directions_walk_rounded,
                color: Colors.cyanAccent.shade400,
                onTap: onMetricTap != null ? () => onMetricTap!(MetricType.steps) : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Calories',
                value: "${calories.toInt()} kcal",
                target: '2,400',
                progress: (calories / 2400.0).clamp(0.0, 1.0),
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
              child: _MetricCard(
                label: 'Sleep',
                value: "${sleepHours}h",
                target: '8.0h',
                progress: (sleepMin / 480.0).clamp(0.0, 1.0),
                icon: Icons.bedtime_rounded,
                color: Colors.purpleAccent.shade100,
                onTap: onMetricTap != null ? () => onMetricTap!(MetricType.sleepDuration) : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
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
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String target;
  final double progress;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.target,
    required this.progress,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF141C2B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF1E293B),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: const Color(0xFF1E293B),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
