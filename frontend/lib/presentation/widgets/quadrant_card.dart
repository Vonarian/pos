import 'package:flutter/material.dart';

import '../../domain/models/routine_item.dart';
import 'routine_item_tile.dart';

class QuadrantCard extends StatelessWidget {
  final String title;
  final String timeRange;
  final IconData icon;
  final bool isActive;
  final List<RoutineItem> items;
  final Function(String id) onComplete;
  final Function(String id) onRevert;
  final Function(String id) onSkip;
  final Function(String id) onDefer;
  final Function(RoutineItem item)? onEdit;
  final Function(String id)? onDelete;

  const QuadrantCard({
    super.key,
    required this.title,
    required this.timeRange,
    required this.icon,
    required this.isActive,
    required this.items,
    required this.onComplete,
    required this.onRevert,
    required this.onSkip,
    required this.onDefer,
    this.onEdit,
    this.onDelete,
  });

  Widget _buildHeader(BuildContext context, int completed, int total) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isActive
                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? theme.colorScheme.primary : Colors.grey.shade400,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                timeRange,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
        Text(
          '$completed/$total',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color:
                completed == total && total > 0
                    ? Colors.teal
                    : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed =
        items.where((i) => i.status == ItemStatus.completed).length;
    final total = items.length;
    final progress = total == 0 ? 1.0 : completed / total;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                  : theme.dividerColor.withValues(alpha: 0.2),
          width: isActive ? 2.0 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, completed, total),
            const SizedBox(height: 12),
            if (total > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: Colors.grey.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0 ? Colors.teal : theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...items.map(
                (item) => RoutineItemTile(
                  item: item,
                  onComplete: () => onComplete(item.id),
                  onRevert: () => onRevert(item.id),
                  onSkip: () => onSkip(item.id),
                  onDefer: () => onDefer(item.id),
                  onEdit: onEdit != null ? () => onEdit!(item) : null,
                  onDelete: onDelete != null ? () => onDelete!(item.id) : null,
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    'No habits scheduled for this window',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
