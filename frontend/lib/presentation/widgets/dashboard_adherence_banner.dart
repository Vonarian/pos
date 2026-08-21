import 'package:flutter/material.dart';

import '../providers/routine_provider.dart';

class DashboardAdherenceBanner extends StatelessWidget {
  final QuadrantState state;

  const DashboardAdherenceBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  "${(state.adherenceRate * 100).toInt()}% Done (${state.completedCount}/${state.totalCount})",
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
              value: state.adherenceRate,
              strokeWidth: 4,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}
