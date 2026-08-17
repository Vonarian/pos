import 'package:flutter/material.dart';

import '../../domain/models/routine_item.dart';

class RoutineItemMenu extends StatelessWidget {
  final RoutineItem item;
  final VoidCallback onComplete;
  final VoidCallback onRevert;
  final VoidCallback onSkip;
  final VoidCallback onDefer;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RoutineItemMenu({
    super.key,
    required this.item,
    required this.onComplete,
    required this.onRevert,
    required this.onSkip,
    required this.onDefer,
    this.onEdit,
    this.onDelete,
  });

  void _handleSelected(String value) {
    switch (value) {
      case 'edit':
        onEdit?.call();
        break;
      case 'revert':
        onRevert();
        break;
      case 'complete':
        onComplete();
        break;
      case 'defer':
        onDefer();
        break;
      case 'skip':
        onSkip();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    Color color,
    String label, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: isDestructive ? TextStyle(color: color) : null,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildItems(
    bool isDone,
    bool isSkipped,
    bool isMissed,
  ) {
    return [
      if (onEdit != null)
        _buildMenuItem(
          'edit',
          Icons.edit_outlined,
          Colors.cyanAccent.shade400,
          'Edit Habit',
        ),
      if (isDone || isSkipped || isMissed)
        _buildMenuItem(
          'revert',
          Icons.undo_rounded,
          Colors.amber,
          'Revert to Pending',
        ),
      if (!isDone)
        _buildMenuItem(
          'complete',
          Icons.check_circle_outline_rounded,
          Colors.teal,
          'Mark as Done',
        ),
      if (!isDone)
        _buildMenuItem(
          'defer',
          Icons.schedule_send_rounded,
          Colors.blueAccent,
          'Defer to Next Window',
        ),
      if (!isDone && !isSkipped)
        _buildMenuItem(
          'skip',
          Icons.close_rounded,
          Colors.grey,
          'Skip for Today',
        ),
      if (onDelete != null)
        _buildMenuItem(
          'delete',
          Icons.delete_outline_rounded,
          Colors.redAccent,
          'Delete Habit',
          isDestructive: true,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDone = item.status == ItemStatus.completed;
    final isSkipped = item.status == ItemStatus.skipped;
    final isMissed = item.status == ItemStatus.missed;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
      onSelected: _handleSelected,
      itemBuilder: (context) => _buildItems(isDone, isSkipped, isMissed),
    );
  }
}
