import 'package:flutter/material.dart';

class AnalyticsStatRow extends StatelessWidget {
  final String latestVal;
  final String avg;
  final String peak;
  final Color avgColor;

  const AnalyticsStatRow({
    super.key,
    required this.latestVal,
    required this.avg,
    required this.peak,
    required this.avgColor,
  });

  Widget _buildStatColumn(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: label == 'Today' ? 22 : 18,
            fontWeight: FontWeight.bold,
            color: color ?? const Color(0xFFF8FAFC),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatColumn('Today', latestVal),
        _buildStatColumn('Average', avg, color: avgColor),
        _buildStatColumn('Peak', peak),
      ],
    );
  }
}
