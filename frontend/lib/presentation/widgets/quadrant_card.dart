import 'package:material_ui/material_ui.dart';

import '../../domain/models/routine_item.dart';
import 'routine_item_tile.dart';

class QuadrantCard extends StatelessWidget {
  final String title;
  final String timeRange;
  final IconData icon;
  final bool isActive;
  final List<RoutineItem> items;
  final Function(String id) onComplete;
  final Function(String id) onSkip;
  final Function(String id) onDefer;

  const QuadrantCard({
    super.key,
    required this.title,
    required this.timeRange,
    required this.icon,
    required this.isActive,
    required this.items,
    required this.onComplete,
    required this.onSkip,
    required this.onDefer,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = items
        .where((i) => i.status == ItemStatus.completed)
        .length;
    final totalCount = items.length;
    final progress = totalCount == 0 ? 1.0 : completedCount / totalCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
              : Theme.of(context).dividerColor.withValues(alpha: 0.2),
          width: isActive ? 2.0 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade600,
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
                                color: Theme.of(context).colorScheme.primary,
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress count
                Text(
                  '$completedCount/$totalCount',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: completedCount == totalCount && totalCount > 0
                        ? Colors.teal
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            if (totalCount > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: Colors.grey.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0
                        ? Colors.teal
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // List of items
              ...items.map(
                (item) => RoutineItemTile(
                  item: item,
                  onComplete: () => onComplete(item.id),
                  onSkip: () => onSkip(item.id),
                  onDefer: () => onDefer(item.id),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }
}
