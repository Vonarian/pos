import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/metric_provider.dart';
import '../providers/routine_provider.dart';

class SyncAppBarButton extends ConsumerStatefulWidget {
  const SyncAppBarButton({super.key});

  @override
  ConsumerState<SyncAppBarButton> createState() => _SyncAppBarButtonState();
}

class _SyncAppBarButtonState extends ConsumerState<SyncAppBarButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isSyncing = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
      _showSuccess = false;
    });
    _controller.repeat();

    final repo = ref.read(offlineRoutineRepositoryProvider);
    try {
      await repo.syncWithServer();
      ref.invalidate(routinesStreamProvider);
      ref.invalidate(dailyMetricSummaryProvider);
    } finally {
      if (mounted) {
        _controller.stop();
        _controller.reset();
        setState(() {
          _isSyncing = false;
          _showSuccess = true;
        });
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          setState(() {
            _showSuccess = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;
    if (_showSuccess) {
      iconWidget = const Icon(Icons.check_rounded, color: Colors.teal);
    } else if (_isSyncing) {
      iconWidget = RotationTransition(
        turns: _controller,
        child: const Icon(Icons.sync_rounded),
      );
    } else {
      iconWidget = const Icon(Icons.sync_rounded);
    }

    return IconButton(
      icon: iconWidget,
      tooltip: 'Sync now',
      onPressed: _isSyncing ? null : _handleSync,
    );
  }
}
