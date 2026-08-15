import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/routine_item.dart';
import 'routine_item_menu.dart';
import 'routine_item_tile_content.dart';

class RoutineItemTile extends StatefulWidget {
  final RoutineItem item;
  final VoidCallback onComplete;
  final VoidCallback onRevert;
  final VoidCallback onSkip;
  final VoidCallback onDefer;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RoutineItemTile({
    super.key,
    required this.item,
    required this.onComplete,
    required this.onRevert,
    required this.onSkip,
    required this.onDefer,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<RoutineItemTile> createState() => _RoutineItemTileState();
}

class _RoutineItemTileState extends State<RoutineItemTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.25,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.25,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInBack)),
        weight: 50.0,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleToggle() {
    HapticFeedback.lightImpact();
    _controller.forward(from: 0.0);
    if (widget.item.status == ItemStatus.completed) {
      widget.onRevert();
    } else {
      widget.onComplete();
    }
  }

  Widget _buildCheckmark(bool isDone, bool isSkipped) {
    final iconData =
        isDone
            ? Icons.check_circle_rounded
            : isSkipped
            ? Icons.remove_circle_outline_rounded
            : Icons.radio_button_unchecked_rounded;
    final iconColor = isDone ? Colors.teal : Colors.grey.shade400;

    return ScaleTransition(
      key: const Key('routine_tile_scale_transition'),
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(iconData, color: iconColor, size: 26),
        onPressed: _handleToggle,
        tooltip: isDone ? 'Revert to Pending' : 'Mark as Done',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.item.status == ItemStatus.completed;
    final isSkipped = widget.item.status == ItemStatus.skipped;
    final isMissed = widget.item.status == ItemStatus.missed;

    Color cardBg = Theme.of(context).cardColor;
    if (isDone) cardBg = Colors.teal.withValues(alpha: 0.08);
    if (isSkipped) cardBg = Colors.grey.withValues(alpha: 0.06);
    if (isMissed) cardBg = Colors.red.withValues(alpha: 0.06);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDone
                  ? Colors.teal.withValues(alpha: 0.3)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _handleToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _buildCheckmark(isDone, isSkipped),
                const SizedBox(width: 8),
                Expanded(
                  child: RoutineItemTileContent(
                    item: widget.item,
                    isDone: isDone,
                    isSkipped: isSkipped,
                  ),
                ),
                RoutineItemMenu(
                  item: widget.item,
                  onComplete: widget.onComplete,
                  onRevert: widget.onRevert,
                  onSkip: widget.onSkip,
                  onDefer: widget.onDefer,
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
