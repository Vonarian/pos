import 'package:flutter/material.dart';

import '../../domain/models/routine_item.dart';
import 'routine_category_chip.dart';

class RoutineItemTileContent extends StatelessWidget {
  final RoutineItem item;
  final bool isDone;
  final bool isSkipped;

  const RoutineItemTileContent({
    super.key,
    required this.item,
    required this.isDone,
    required this.isSkipped,
  });

  Widget _buildReminderBadge(String time) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.alarm, size: 12, color: Colors.blueGrey),
          const SizedBox(width: 3),
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInactive = isDone || isSkipped;
    final defaultColor = Theme.of(context).textTheme.bodyMedium?.color;
    final reminder = item.reminderConfig;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            RoutineCategoryChip(
              category: item.category,
              metadata: item.metadata,
            ),
            if (reminder != null && reminder.enabled)
              _buildReminderBadge(reminder.time),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            decoration: isInactive ? TextDecoration.lineThrough : null,
            color: isInactive ? Colors.grey : defaultColor,
          ),
          child: Text(item.title),
        ),
        if (item.metadata['dosage'] != null) ...[
          const SizedBox(height: 2),
          Text(
            'Dosage: ${item.metadata['dosage']}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ],
    );
  }
}
