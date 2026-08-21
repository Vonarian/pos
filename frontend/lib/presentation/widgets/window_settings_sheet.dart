import 'package:flutter/material.dart';

import '../../domain/models/window_settings.dart';

class WindowSettingsSheet extends StatefulWidget {
  final WindowSettings initialSettings;
  final ValueChanged<WindowSettings> onSave;

  const WindowSettingsSheet({
    super.key,
    required this.initialSettings,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required WindowSettings settings,
    required ValueChanged<WindowSettings> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => WindowSettingsSheet(
        initialSettings: settings,
        onSave: (val) {
          onSave(val);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  State<WindowSettingsSheet> createState() => _WindowSettingsSheetState();
}

class _WindowSettingsSheetState extends State<WindowSettingsSheet> {
  late bool _nudgesEnabled;
  late int _nudgeLeadMinutes;

  @override
  void initState() {
    super.initState();
    _nudgesEnabled = widget.initialSettings.windowNudgesEnabled;
    _nudgeLeadMinutes = widget.initialSettings.nudgeLeadMinutes;
  }

  void _handleSave() {
    final updated = WindowSettings(
      morningStartHour: widget.initialSettings.morningStartHour,
      morningEndHour: widget.initialSettings.morningEndHour,
      afternoonStartHour: widget.initialSettings.afternoonStartHour,
      afternoonEndHour: widget.initialSettings.afternoonEndHour,
      eveningStartHour: widget.initialSettings.eveningStartHour,
      eveningEndHour: widget.initialSettings.eveningEndHour,
      nightStartHour: widget.initialSettings.nightStartHour,
      nightEndHour: widget.initialSettings.nightEndHour,
      nudgeLeadMinutes: _nudgeLeadMinutes,
      windowNudgesEnabled: _nudgesEnabled,
    );
    widget.onSave(updated);
  }

  Widget _buildLeadTimeSelector() {
    const options = [15, 30, 45, 60];
    return Wrap(
      spacing: 8,
      children: options.map((m) {
        return ChoiceChip(
          label: Text('${m}m before'),
          selected: _nudgeLeadMinutes == m,
          onSelected: (_) => setState(() => _nudgeLeadMinutes = m),
        );
      }).toList(),
    );
  }

  Widget _buildControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Time-Window Closing Nudges'),
          subtitle: const Text('Safety-net alerts for pending habits'),
          value: _nudgesEnabled,
          onChanged: (val) => setState(() => _nudgesEnabled = val),
        ),
        if (_nudgesEnabled) ...[
          const SizedBox(height: 8),
          const Text(
            'Nudge Warning Lead Time:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildLeadTimeSelector(),
        ],
      ],
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
          const Text(
            'Window & Reminder Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildControls(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _handleSave,
              child: const Text('Save Configuration'),
            ),
          ),
        ],
      ),
    );
  }
}
