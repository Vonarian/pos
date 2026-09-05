import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/metric_provider.dart';
import '../providers/routine_provider.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';

class CurrentTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void select(int index) => state = index;
}

final currentTabProvider = NotifierProvider<CurrentTabNotifier, int>(
  CurrentTabNotifier.new,
);

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(routinesStreamProvider);
      ref.invalidate(dailyMetricSummaryProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(currentTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: activeTab,
        children: const [DashboardScreen(), AnalyticsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeTab,
        onDestinationSelected: (index) {
          ref.read(currentTabProvider.notifier).select(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

