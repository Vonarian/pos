import 'package:flutter/material.dart';

class EditRoutineScopeCard extends StatelessWidget {
  final bool applyToFuture;
  final ValueChanged<bool> onChanged;

  const EditRoutineScopeCard({
    super.key,
    required this.applyToFuture,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF141C2B),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Apply to all future occurrences',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Updates recurring schedule and future tickets',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          value: applyToFuture,
          activeColor: Colors.tealAccent.shade400,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
