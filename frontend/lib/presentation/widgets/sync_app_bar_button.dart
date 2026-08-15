import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/native/health_connect_channel.dart';
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
      final raw = await HealthConnectChannel.getRawHealthData(days: 14);
      final sleep = raw['sleep'] as List? ?? [];
      final totalCal = raw['totalCalories'] as List? ?? [];
      final activeCal = raw['activeCalories'] as List? ?? [];
      final weight = raw['weight'] as List? ?? [];
      final steps = raw['steps'] as List? ?? [];

      debugPrint('=== [RAW_HEALTH_DUMP] ===');
      for (final s in sleep) {
        debugPrint('[RAW_SLEEP_RECORD] $s');
      }
      for (final c in totalCal) {
        debugPrint('[RAW_TOTAL_CAL_RECORD] $c');
      }
      for (final a in activeCal) {
        debugPrint('[RAW_ACTIVE_CAL_RECORD] $a');
      }
      for (final w in weight) {
        debugPrint('[RAW_WEIGHT_RECORD] $w');
      }
      debugPrint('[RAW_STEPS_SUMMARY] total steps chunks: ${steps.length}');

      await repo.syncWithServer();
      ref.invalidate(routinesStreamProvider);
      ref.invalidate(dailyMetricSummaryProvider);
      ref.invalidate(metricSeriesProvider);
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
