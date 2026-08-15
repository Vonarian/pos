import 'package:flutter/material.dart';

class QuickLogBanner extends StatelessWidget {
  final VoidCallback onLogTap;

  const QuickLogBanner({super.key, required this.onLogTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit_calendar_rounded,
              color: Colors.blueAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manual Entry',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF8FAFC),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Log weight, water intake, or custom metrics',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: onLogTap,
            child: const Text('Add Entry'),
          ),
        ],
      ),
    );
  }
}
