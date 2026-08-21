import 'package:flutter/material.dart';

import '../../domain/models/reminder_config.dart';

class ReminderPickerSection extends StatelessWidget {
  final ReminderConfig config;
  final ValueChanged<ReminderConfig> onChanged;

  const ReminderPickerSection({
    super.key,
    required this.config,
    required this.onChanged,
  });

  Future<void> _pickTime(BuildContext context) async {
    final parts = config.time.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selected != null) {
      final hourStr = selected.hour.toString().padLeft(2, '0');
      final minStr = selected.minute.toString().padLeft(2, '0');
      onChanged(config.copyWith(time: '$hourStr:$minStr'));
    }
  }

  Widget _buildTimePickerButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _pickTime(context),
      icon: const Icon(Icons.access_time, size: 18),
      label: Text(
        config.time,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        ChoiceChip(
          label: const Text('Once / Tonight'),
          selected: config.isOneTime,
          onSelected: (_) => onChanged(config.copyWith(isRecurring: false)),
        ),
        ChoiceChip(
          label: const Text('Repeating Habit'),
          selected: config.isRecurring,
          onSelected: (_) => onChanged(config.copyWith(isRecurring: true)),
        ),
      ],
    );
  }

  Widget _buildOneTimePresets() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ActionChip(
          label: const Text('Tonight 9 PM'),
          avatar: const Icon(Icons.nightlight_round, size: 16),
          onPressed: () => onChanged(config.copyWith(time: '21:00', isRecurring: false)),
        ),
        ActionChip(
          label: const Text('In 1 Hour'),
          avatar: const Icon(Icons.timer_outlined, size: 16),
          onPressed: () {
            final target = DateTime.now().add(const Duration(hours: 1));
            final h = target.hour.toString().padLeft(2, '0');
            final m = target.minute.toString().padLeft(2, '0');
            onChanged(config.copyWith(time: '$h:$m', isRecurring: false));
          },
        ),
        ActionChip(
          label: const Text('Morning 8 AM'),
          avatar: const Icon(Icons.wb_sunny_outlined, size: 16),
          onPressed: () => onChanged(config.copyWith(time: '08:00', isRecurring: false)),
        ),
      ],
    );
  }

  Widget _buildDayFilterChips() {
    const days = [
      {'label': 'M', 'val': 1},
      {'label': 'T', 'val': 2},
      {'label': 'W', 'val': 3},
      {'label': 'T', 'val': 4},
      {'label': 'F', 'val': 5},
      {'label': 'S', 'val': 6},
      {'label': 'S', 'val': 7},
    ];

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: days.map((d) {
        final val = d['val'] as int;
        final isSelected = config.daysOfWeek.contains(val);
        return FilterChip(
          label: Text(d['label'] as String),
          selected: isSelected,
          onSelected: (selected) {
            final list = List<int>.from(config.daysOfWeek);
            if (selected) {
              list.add(val);
            } else {
              list.remove(val);
            }
            list.sort();
            onChanged(config.copyWith(daysOfWeek: list, isRecurring: true));
          },
        );
      }).toList(),
    );
  }

  Widget _buildRepeatingPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: const Text('Daily'),
              selected: config.isDaily,
              onSelected: (_) => onChanged(config.copyWith(daysOfWeek: const [], isRecurring: true)),
            ),
            ChoiceChip(
              label: const Text('Weekdays'),
              selected:
                  config.daysOfWeek.length == 5 &&
                  !config.daysOfWeek.contains(6) &&
                  !config.daysOfWeek.contains(7),
              onSelected: (_) =>
                  onChanged(config.copyWith(daysOfWeek: [1, 2, 3, 4, 5], isRecurring: true)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildDayFilterChips(),
      ],
    );
  }

  Widget _buildExpandedControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildModeSelector(),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Alert Time: '),
            _buildTimePickerButton(context),
          ],
        ),
        const SizedBox(height: 8),
        if (config.isOneTime) _buildOneTimePresets() else _buildRepeatingPresets(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active_outlined, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Set Reminder Alert',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Switch(
                value: config.enabled,
                onChanged: (val) => onChanged(config.copyWith(enabled: val)),
              ),
            ],
          ),
          if (config.enabled) _buildExpandedControls(context),
        ],
      ),
    );
  }
}

