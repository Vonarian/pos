import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/models/reminder_config.dart';
import '../../domain/models/routine_item.dart';
import '../../domain/models/window_settings.dart';
import '../native/notification_service.dart';

class ReminderSchedulerService {
  static Future<void> _syncLock = Future.value();

  static DateTime? calculateReminderTrigger({
    required RoutineItem item,
    required DateTime now,
  }) {
    final config = item.reminderConfig;
    if (config == null || !config.enabled) return null;

    if (item.status == ItemStatus.pending &&
        config.lastSnoozedUntil != null &&
        config.lastSnoozedUntil!.isAfter(now)) {
      return config.lastSnoozedUntil;
    }

    final parts = config.time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    if (config.isOneTime) {
      if (item.status != ItemStatus.pending) return null;
      final s = DateTime.tryParse(item.scheduledDate);
      if (s == null) return null;
      final trigger = DateTime(s.year, s.month, s.day, hour, minute);
      return trigger.isAfter(now) ? trigger : null;
    }

    return _nextRecurringTrigger(item, config, now, hour, minute);
  }

  static DateTime? _nextRecurringTrigger(
    RoutineItem item,
    ReminderConfig config,
    DateTime now,
    int hour,
    int minute,
  ) {
    if (item.status == ItemStatus.pending &&
        config.isScheduledForDay(now.weekday)) {
      final todayTrigger = DateTime(now.year, now.month, now.day, hour, minute);
      if (todayTrigger.isAfter(now)) return todayTrigger;
    }
    final base = DateTime(now.year, now.month, now.day);
    for (var offset = 1; offset <= 7; offset++) {
      final d = base.add(Duration(days: offset));
      if (config.isScheduledForDay(d.weekday)) {
        return DateTime(d.year, d.month, d.day, hour, minute);
      }
    }
    return null;
  }

  static DateTime calculateWindowNudgeTrigger({
    required TimeWindow window,
    required WindowSettings settings,
    required DateTime now,
  }) {
    final closing = settings.getClosingTime(now, window);
    return closing.subtract(Duration(minutes: settings.nudgeLeadMinutes));
  }

  static bool shouldTriggerWindowNudge({
    required TimeWindow window,
    required List<RoutineItem> routinesInWindow,
    required WindowSettings settings,
    required DateTime now,
  }) {
    if (!settings.windowNudgesEnabled) return false;
    final nudgeTime = calculateWindowNudgeTrigger(
      window: window,
      settings: settings,
      now: now,
    );
    if (!nudgeTime.isAfter(now)) return false;

    return routinesInWindow.any((item) => item.status == ItemStatus.pending);
  }

  static Future<void> syncAll({
    required List<RoutineItem> routines,
    required WindowSettings settings,
    DateTime? currentTime,
  }) {
    final previous = _syncLock;
    final next = previous.catchError((_) {}).then((_) async {
      final now = currentTime ?? DateTime.now();
      final habitIds = await _syncHabitReminders(routines, now);
      final windowIds = await _syncWindowNudges(routines, settings, now);
      await NativeNotificationService.cancelOrphanReminders({...habitIds, ...windowIds});
    });
    _syncLock = next;
    return next;
  }

  static DateTimeComponents? _resolveMatchComponents(
    RoutineItem item,
    DateTime now,
  ) {
    final config = item.reminderConfig;
    if (config == null || config.isOneTime) return null;
    if (item.status == ItemStatus.pending &&
        config.lastSnoozedUntil != null &&
        config.lastSnoozedUntil!.isAfter(now)) {
      return null;
    }
    return config.isDaily
        ? DateTimeComponents.time
        : DateTimeComponents.dayOfWeekAndTime;
  }

  static Future<Set<int>> _syncHabitReminders(
    List<RoutineItem> routines,
    DateTime now,
  ) async {
    final activeIds = <int>{};
    for (final item in routines) {
      final trigger = calculateReminderTrigger(item: item, now: now);
      if (trigger != null) {
        final id = NativeNotificationService.getNotificationIdForRoutine(
          item.id,
        );
        activeIds.add(id);
        final snoozeMins = item.reminderConfig?.snoozeMinutes ?? 15;
        await NativeNotificationService.scheduleHabitReminder(
          routineId: item.id,
          title: item.title,
          body: 'Scheduled reminder for ${item.title}',
          scheduledDate: trigger,
          snoozeMinutes: snoozeMins,
          matchDateTimeComponents: _resolveMatchComponents(item, now),
        );
      } else {
        await NativeNotificationService.cancelHabitReminder(item.id);
      }
    }
    return activeIds;
  }

  static Future<Set<int>> _syncWindowNudges(
    List<RoutineItem> routines,
    WindowSettings settings,
    DateTime now,
  ) async {
    final activeIds = <int>{};
    final todayStr = _formatDate(now);
    for (final window in TimeWindow.values) {
      final itemsInWindow = routines
          .where((e) => e.scheduledDate == todayStr && e.timeWindow == window)
          .toList();
      if (shouldTriggerWindowNudge(
        window: window,
        routinesInWindow: itemsInWindow,
        settings: settings,
        now: now,
      )) {
        activeIds.add(NativeNotificationService.getNotificationIdForWindow(window));
        final pending = itemsInWindow
            .where((e) => e.status == ItemStatus.pending)
            .map((e) => e.title)
            .take(3)
            .join(', ');
        await NativeNotificationService.scheduleWindowNudge(
          window: window,
          title: 'POS: ${window.name.toUpperCase()} Window Ending',
          body: 'Pending items: $pending',
          scheduledDate: calculateWindowNudgeTrigger(
            window: window,
            settings: settings,
            now: now,
          ),
        );
      } else {
        await NativeNotificationService.cancelWindowNudge(window);
      }
    }
    return activeIds;
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
