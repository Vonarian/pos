import 'package:flutter/material.dart';

import '../../domain/models/reminder_config.dart';

class ReminderDayFilter extends StatelessWidget {
  final ReminderConfig config;
  final ValueChanged<ReminderConfig> onChanged;

  const ReminderDayFilter({
    super.key,
    required this.config,
    required this.onChanged,
  });

  static const _days = [
    (label: 'M', val: 1),
    (label: 'T', val: 2),
    (label: 'W', val: 3),
    (label: 'T', val: 4),
    (label: 'F', val: 5),
    (label: 'S', val: 6),
    (label: 'S', val: 7),
  ];

  void _toggleDay(int val, bool selected) {
    final list = List<int>.from(config.daysOfWeek);
    if (selected) {
      list.add(val);
    } else {
      list.remove(val);
    }
    list.sort();
    onChanged(config.copyWith(daysOfWeek: list, isRecurring: true));
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final d in _days)
          FilterChip(
            label: Text(d.label),
            selected: config.daysOfWeek.contains(d.val),
            onSelected: (selected) => _toggleDay(d.val, selected),
          ),
      ],
    );
  }
}
