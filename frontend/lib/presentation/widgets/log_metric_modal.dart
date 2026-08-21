import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/health_data_point.dart';
import '../providers/metric_provider.dart';

class LogMetricModal extends ConsumerStatefulWidget {
  final MetricType initialMetric;

  const LogMetricModal({super.key, required this.initialMetric});

  @override
  ConsumerState<LogMetricModal> createState() => _LogMetricModalState();
}

class _LogMetricModalState extends ConsumerState<LogMetricModal> {
  late MetricType _selectedMetric;
  final _valueController = TextEditingController();
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _selectedMetric = widget.initialMetric;
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  String _getUnit() {
    switch (_selectedMetric) {
      case MetricType.steps:
        return 'count';
      case MetricType.caloriesConsumed:
      case MetricType.caloriesBurned:
        return 'kcal';
      case MetricType.sleepDuration:
        return 'minutes';
      case MetricType.weight:
        return 'kg';
      case MetricType.waterIntake:
        return 'ml';
      default:
        return 'units';
    }
  }

  Future<void> _saveMetric() async {
    final text = _valueController.text.trim();
    final val = double.tryParse(text);
    if (val == null || val <= 0) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(offlineMetricRepositoryProvider);
      await repo.logManualMetric(
        metric: _selectedMetric,
        value: val,
        unit: _getUnit(),
      );

      ref.invalidate(metricSeriesProvider);
      ref.invalidate(dailyMetricSummaryProvider);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSaved = true;
        });
        await Future.delayed(const Duration(milliseconds: 250));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Log Health Metric',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF8FAFC),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildMetricDropdown() {
    return DropdownButtonFormField<MetricType>(
      initialValue: _selectedMetric,
      decoration: InputDecoration(
        labelText: 'Metric Type',
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E293B)),
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: MetricType.caloriesConsumed,
          child: Text('🍲 Food Intake (kcal)'),
        ),
        DropdownMenuItem(
          value: MetricType.caloriesBurned,
          child: Text('🔥 Active Calories (kcal)'),
        ),
        DropdownMenuItem(
          value: MetricType.weight,
          child: Text('⚖️ Weight (kg)'),
        ),
        DropdownMenuItem(
          value: MetricType.waterIntake,
          child: Text('💧 Water Intake (ml)'),
        ),
        DropdownMenuItem(
          value: MetricType.sleepDuration,
          child: Text('😴 Sleep (minutes)'),
        ),
        DropdownMenuItem(
          value: MetricType.steps,
          child: Text('🚶 Steps (count)'),
        ),
      ],
      onChanged: (val) {
        if (val != null) setState(() => _selectedMetric = val);
      },
    );
  }

  Widget _buildSaveButton() {
    Widget child;
    if (_isSaving) {
      child = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    } else if (_isSaved) {
      child = const Icon(Icons.check_rounded, color: Colors.white, size: 24);
    } else {
      child = const Text(
        'Save Entry',
        style: TextStyle(fontWeight: FontWeight.bold),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: (_isSaving || _isSaved) ? null : _saveMetric,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 14),
          _buildMetricDropdown(),
          const SizedBox(height: 14),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Value (${_getUnit()})',
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E293B)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSaveButton(),
        ],
      ),
    );
  }
}
