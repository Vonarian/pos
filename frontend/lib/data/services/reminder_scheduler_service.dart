import '../../domain/models/routine_item.dart';
import '../../domain/models/window_settings.dart';
import '../native/notification_service.dart';

class ReminderSchedulerService {
  static DateTime? calculateReminderTrigger({
    required RoutineItem item,
    required DateTime now,
  }) {
    if (item.status != ItemStatus.pending) return null;
    final config = item.reminderConfig;
    if (config == null || !config.enabled) return null;
    if (!config.isScheduledForDay(now.weekday)) return null;

    final parts = config.time.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    final trigger = DateTime(now.year, now.month, now.day, hour, minute);
    return trigger.isAfter(now) ? trigger : null;
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
  }) async {
    final now = currentTime ?? DateTime.now();
    await _syncHabitReminders(routines, now);
    await _syncWindowNudges(routines, settings, now);
  }

  static Future<void> _syncHabitReminders(
    List<RoutineItem> routines,
    DateTime now,
  ) async {
    for (final item in routines) {
      final trigger = calculateReminderTrigger(item: item, now: now);
      if (trigger != null) {
        final snoozeMins = item.reminderConfig?.snoozeMinutes ?? 15;
        await NativeNotificationService.scheduleHabitReminder(
          routineId: item.id,
          title: item.title,
          body: 'Scheduled reminder for ${item.title}',
          scheduledDate: trigger,
          snoozeMinutes: snoozeMins,
        );
      } else if (item.status == ItemStatus.completed ||
          item.status == ItemStatus.skipped) {
        await NativeNotificationService.cancelHabitReminder(item.id);
      }
    }
  }

  static Future<void> _syncWindowNudges(
    List<RoutineItem> routines,
    WindowSettings settings,
    DateTime now,
  ) async {
    for (final window in TimeWindow.values) {
      final itemsInWindow =
          routines.where((e) => e.timeWindow == window).toList();
      final shouldTrigger = shouldTriggerWindowNudge(
        window: window,
        routinesInWindow: itemsInWindow,
        settings: settings,
        now: now,
      );

      if (shouldTrigger) {
        final pending =
            itemsInWindow
                .where((e) => e.status == ItemStatus.pending)
                .map((e) => e.title)
                .take(3)
                .join(', ');
        final trigger = calculateWindowNudgeTrigger(
          window: window,
          settings: settings,
          now: now,
        );
        await NativeNotificationService.scheduleWindowNudge(
          window: window,
          title: 'POS: ${window.name.toUpperCase()} Window Ending',
          body: 'Pending items: $pending',
          scheduledDate: trigger,
        );
      } else {
        await NativeNotificationService.cancelWindowNudge(window);
      }
    }
  }
}
