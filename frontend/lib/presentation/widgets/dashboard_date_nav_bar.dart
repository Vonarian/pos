import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/routine_provider.dart';

class DashboardDateNavBar extends StatelessWidget {
  final WidgetRef ref;
  final String date;
  final bool isToday;

  const DashboardDateNavBar({
    super.key,
    required this.ref,
    required this.date,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.parse(date);
    final dateLabel = isToday
        ? "Today (${DateFormat('MMM d').format(parsed)})"
        : DateFormat('EEEE, MMM d').format(parsed);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () {
            final prev = parsed.subtract(const Duration(days: 1));
            ref
                .read(selectedDateProvider.notifier)
                .setDate(DateFormat('yyyy-MM-dd').format(prev));
          },
        ),
        Text(
          dateLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () {
            final next = parsed.add(const Duration(days: 1));
            ref
                .read(selectedDateProvider.notifier)
                .setDate(DateFormat('yyyy-MM-dd').format(next));
          },
        ),
      ],
    );
  }
}
