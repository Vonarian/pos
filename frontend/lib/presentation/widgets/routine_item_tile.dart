import 'package:material_ui/material_ui.dart';

import '../../domain/models/routine_item.dart';

class RoutineItemTile extends StatelessWidget {
  final RoutineItem item;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final VoidCallback onDefer;

  const RoutineItemTile({
    super.key,
    required this.item,
    required this.onComplete,
    required this.onSkip,
    required this.onDefer,
  });

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'MEDS':
        return Colors.teal;
      case 'WORKOUT':
        return Colors.deepOrange;
      case 'NUTRITION':
        return Colors.green;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = item.status == ItemStatus.completed;
    final isSkipped = item.status == ItemStatus.skipped;
    final isMissed = item.status == ItemStatus.missed;

    Color cardBg = Theme.of(context).cardColor;
    if (isDone) cardBg = Colors.teal.withValues(alpha: 0.08);
    if (isSkipped) cardBg = Colors.grey.withValues(alpha: 0.06);
    if (isMissed) cardBg = Colors.red.withValues(alpha: 0.06);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDone
              ? Colors.teal.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Done Checkbox
            IconButton(
              icon: Icon(
                isDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isDone ? Colors.teal : Colors.grey.shade400,
                size: 26,
              ),
              onPressed: isDone ? null : onComplete,
              tooltip: isDone ? 'Completed' : 'Mark as Done',
            ),
            const SizedBox(width: 8),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(item.category)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getCategoryColor(item.category),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (item.metadata['nfc_tag'] != null)
                        Row(
                          children: [
                            Icon(
                              Icons.nfc_rounded,
                              size: 12,
                              color: Colors.blueGrey.shade400,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'NFC',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blueGrey.shade400,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : isSkipped
                          ? TextDecoration.lineThrough
                          : null,
                      color: isDone || isSkipped ? Colors.grey : null,
                    ),
                  ),
                  if (item.metadata['dosage'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Dosage: ${item.metadata['dosage']}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Actions Menu
            if (!isDone)
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: Colors.grey,
                ),
                onSelected: (value) {
                  if (value == 'defer') onDefer();
                  if (value == 'skip') onSkip();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'defer',
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_send_rounded,
                          size: 18,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 8),
                        Text('Defer to Next Window'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'skip',
                    child: Row(
                      children: [
                        Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Skip for Today'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
