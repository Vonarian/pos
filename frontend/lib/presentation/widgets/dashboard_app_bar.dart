import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/routine_provider.dart';
import 'sync_app_bar_button.dart';
import 'window_settings_sheet.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final WidgetRef ref;

  const DashboardAppBar({super.key, required this.ref});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'POS',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded, size: 20),
          tooltip: 'Window & Reminder Settings',
          onPressed: () {
            WindowSettingsSheet.show(
              context,
              settings: ref.read(windowSettingsProvider),
              onSave:
                  (s) =>
                      ref
                          .read(windowSettingsProvider.notifier)
                          .updateSettings(s),
            );
          },
        ),
        const SyncAppBarButton(),
      ],
    );
  }
}
