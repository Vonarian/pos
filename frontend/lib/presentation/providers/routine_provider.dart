import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/local/database.dart';
import '../../data/remote/api_client.dart';
import '../../data/repositories/offline_routine_repository.dart';
import '../../data/services/reminder_scheduler_service.dart';
import '../../domain/models/routine_item.dart';
import '../../domain/models/window_settings.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final offlineRoutineRepositoryProvider = Provider<OfflineRoutineRepository>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  final client = ref.watch(apiClientProvider);
  return OfflineRoutineRepository(db: db, apiClient: client);
});

class SelectedDateNotifier extends Notifier<String> {
  @override
  String build() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  void setDate(String date) {
    state = date;
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, String>(
  SelectedDateNotifier.new,
);

class WindowSettingsNotifier extends Notifier<WindowSettings> {
  @override
  WindowSettings build() {
    return WindowSettings.defaults();
  }

  void updateSettings(WindowSettings settings) {
    state = settings;
  }
}

final windowSettingsProvider =
    NotifierProvider<WindowSettingsNotifier, WindowSettings>(
      WindowSettingsNotifier.new,
    );

final routinesStreamProvider = StreamProvider.autoDispose<List<RoutineItem>>((
  ref,
) {
  final repo = ref.watch(offlineRoutineRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  return repo.watchRoutinesForDate(date);
});

class QuadrantState {
  final String date;
  final TimeWindow activeWindow;
  final List<RoutineItem> morning;
  final List<RoutineItem> afternoon;
  final List<RoutineItem> evening;
  final List<RoutineItem> night;
  final int totalCount;
  final int completedCount;

  QuadrantState({
    required this.date,
    required this.activeWindow,
    required this.morning,
    required this.afternoon,
    required this.evening,
    required this.night,
    required this.totalCount,
    required this.completedCount,
  });

  double get adherenceRate =>
      totalCount == 0 ? 0.0 : completedCount / totalCount;
}

TimeWindow calculateCurrentWindow(DateTime now, {WindowSettings? settings}) {
  final s = settings ?? WindowSettings.defaults();
  return s.calculateWindow(now);
}

final quadrantStateProvider = Provider.autoDispose<QuadrantState>((ref) {
  final routinesAsync = ref.watch(routinesStreamProvider);
  final date = ref.watch(selectedDateProvider);
  final settings = ref.watch(windowSettingsProvider);
  final activeWindow = calculateCurrentWindow(
    DateTime.now(),
    settings: settings,
  );

  final routines = routinesAsync.value ?? [];

  // Reconcile and synchronize alarms
  ReminderSchedulerService.syncAll(routines: routines, settings: settings);

  final morning = <RoutineItem>[];
  final afternoon = <RoutineItem>[];
  final evening = <RoutineItem>[];
  final night = <RoutineItem>[];

  int completed = 0;

  for (final item in routines) {
    if (item.status == ItemStatus.completed) {
      completed++;
    }
    switch (item.timeWindow) {
      case TimeWindow.morning:
        morning.add(item);
        break;
      case TimeWindow.afternoon:
        afternoon.add(item);
        break;
      case TimeWindow.evening:
        evening.add(item);
        break;
      case TimeWindow.night:
        night.add(item);
        break;
    }
  }

  return QuadrantState(
    date: date,
    activeWindow: activeWindow,
    morning: morning,
    afternoon: afternoon,
    evening: evening,
    night: night,
    totalCount: routines.length,
    completedCount: completed,
  );
});
