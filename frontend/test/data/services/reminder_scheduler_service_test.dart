import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/data/services/reminder_scheduler_service.dart';
import 'package:pos_frontend/domain/models/reminder_config.dart';
import 'package:pos_frontend/domain/models/routine_item.dart';
import 'package:pos_frontend/domain/models/window_settings.dart';

void main() {
  group('ReminderSchedulerService', () {
    late WindowSettings settings;
    final now = DateTime(2026, 8, 15, 8, 0); // Saturday 08:00 AM

    setUp(() {
      settings = WindowSettings.defaults();
    });

    test('calculates scheduled time today for pending habit with reminder', () {
      final config = const ReminderConfig(
        enabled: true,
        isRecurring: true,
        time: '09:30',
        daysOfWeek: [], // Daily
      );

      final item = RoutineItem(
        id: 'habit-1',
        title: 'Morning Creatine',
        category: 'MEDS',
        timeWindow: TimeWindow.morning,
        scheduledDate: '2026-08-15',
        status: ItemStatus.pending,
        metadata: {'reminder': config.toJson()},
        updatedAt: now,
        createdAt: now,
      );

      final scheduledTime = ReminderSchedulerService.calculateReminderTrigger(
        item: item,
        now: now,
      );

      expect(scheduledTime, DateTime(2026, 8, 15, 9, 30));
    });

    test('calculates scheduled time tonight for one-time reminder on matching date', () {
      final config = const ReminderConfig(
        enabled: true,
        isRecurring: false,
        time: '21:00',
      );

      final item = RoutineItem(
        id: 'reminder-tonight-1',
        title: 'Call family tonight',
        category: 'HABIT',
        timeWindow: TimeWindow.night,
        scheduledDate: '2026-08-15',
        status: ItemStatus.pending,
        metadata: {'reminder': config.toJson()},
        updatedAt: now,
        createdAt: now,
      );

      final scheduledTime = ReminderSchedulerService.calculateReminderTrigger(
        item: item,
        now: now,
      );

      expect(scheduledTime, DateTime(2026, 8, 15, 21, 00));
    });

    test('calculates scheduled time for one-time reminder on future date and null on past date', () {
      const config = ReminderConfig(
        enabled: true,
        isRecurring: false,
        time: '21:00',
      );

      final futureItem = RoutineItem(
        id: 'reminder-tomorrow-1',
        title: 'Tomorrow reminder',
        category: 'HABIT',
        timeWindow: TimeWindow.night,
        scheduledDate: '2026-08-16', // Tomorrow
        status: ItemStatus.pending,
        metadata: {'reminder': config.toJson()},
        updatedAt: now,
        createdAt: now,
      );

      expect(
        ReminderSchedulerService.calculateReminderTrigger(
          item: futureItem,
          now: now,
        ),
        DateTime(2026, 8, 16, 21, 0),
      );

      final pastDateItem = futureItem.copyWith(scheduledDate: '2026-08-14');
      expect(
        ReminderSchedulerService.calculateReminderTrigger(
          item: pastDateItem,
          now: now,
        ),
        isNull,
      );
    });

    test('returns null if reminder is disabled or one-time reminder is in the past', () {
      const disabledConfig = ReminderConfig(
        enabled: false,
        time: '09:30',
      );

      final disabledItem = RoutineItem(
        id: 'habit-2',
        title: 'Disabled Habit',
        category: 'MEDS',
        timeWindow: TimeWindow.morning,
        scheduledDate: '2026-08-15',
        status: ItemStatus.pending,
        metadata: {'reminder': disabledConfig.toJson()},
        updatedAt: now,
        createdAt: now,
      );

      expect(
        ReminderSchedulerService.calculateReminderTrigger(
          item: disabledItem,
          now: now,
        ),
        isNull,
      );

      const pastOneTimeConfig = ReminderConfig(
        enabled: true,
        isRecurring: false,
        time: '07:00',
      );
      final pastOneTimeItem = disabledItem.copyWith(
        metadata: {'reminder': pastOneTimeConfig.toJson()},
      );

      expect(
        ReminderSchedulerService.calculateReminderTrigger(
          item: pastOneTimeItem,
          now: now,
        ),
        isNull,
      );
    });

    test('rolls recurring habit to tomorrow when today time passed or already completed', () {
      const recurringPastToday = ReminderConfig(
        enabled: true,
        isRecurring: true,
        time: '07:00',
      );

      final itemPastToday = RoutineItem(
        id: 'habit-recurring-past',
        templateId: 'tpl_habit_1',
        title: 'Morning Thyroid Med',
        category: 'MEDS',
        timeWindow: TimeWindow.morning,
        scheduledDate: '2026-08-15',
        status: ItemStatus.pending,
        metadata: {'reminder': recurringPastToday.toJson()},
        updatedAt: now,
        createdAt: now,
      );

      expect(
        ReminderSchedulerService.calculateReminderTrigger(
          item: itemPastToday,
          now: now,
        ),
        DateTime(2026, 8, 16, 7, 0),
      );

      const recurringFutureToday = ReminderConfig(
        enabled: true,
        isRecurring: true,
        time: '09:30',
      );
      final completedToday = itemPastToday.copyWith(
        status: ItemStatus.completed,
        metadata: {'reminder': recurringFutureToday.toJson()},
      );

      expect(
        ReminderSchedulerService.calculateReminderTrigger(
          item: completedToday,
          now: now,
        ),
        DateTime(2026, 8, 16, 9, 30),
      );
    });

    test('calculates next valid weekday for weekday-only recurring habit on weekend', () {
      // 2026-08-15 is Saturday (weekday = 6) -> next valid is Monday 2026-08-17
      const weekdaysOnlyConfig = ReminderConfig(
        enabled: true,
        isRecurring: true,
        time: '09:30',
        daysOfWeek: [1, 2, 3, 4, 5],
      );

      final item = RoutineItem(
        id: 'habit-3',
        templateId: 'tpl_habit_3',
        title: 'Weekday Habit',
        category: 'MEDS',
        timeWindow: TimeWindow.morning,
        scheduledDate: '2026-08-15',
        status: ItemStatus.pending,
        metadata: {'reminder': weekdaysOnlyConfig.toJson()},
        updatedAt: now,
        createdAt: now,
      );

      expect(
        ReminderSchedulerService.calculateReminderTrigger(item: item, now: now),
        DateTime(2026, 8, 17, 9, 30),
      );
    });

    test('preserves active snooze time for pending item and ignores snooze if completed', () {
      final snoozedUntil = DateTime(2026, 8, 15, 8, 15);
      final snoozedConfig = ReminderConfig(
        enabled: true,
        isRecurring: true,
        time: '07:30',
        lastSnoozedUntil: snoozedUntil,
      );

      final pendingSnoozed = RoutineItem(
        id: 'habit-snoozed',
        templateId: 'tpl_snoozed',
        title: 'Omega-3',
        category: 'MEDS',
        timeWindow: TimeWindow.morning,
        scheduledDate: '2026-08-15',
        status: ItemStatus.pending,
        metadata: {'reminder': snoozedConfig.toJson()},
        updatedAt: now,
        createdAt: now,
      );

      expect(
        ReminderSchedulerService.calculateReminderTrigger(
          item: pendingSnoozed,
          now: now,
        ),
        snoozedUntil,
      );

      final completedSnoozed = pendingSnoozed.copyWith(
        status: ItemStatus.completed,
      );
      expect(
        ReminderSchedulerService.calculateReminderTrigger(
          item: completedSnoozed,
          now: now,
        ),
        DateTime(2026, 8, 16, 7, 30),
      );
    });

    test('calculateWindowNudgeTrigger returns correct warning time', () {
      // Morning closing is 12:00, nudge lead time is 30 mins -> 11:30 AM
      final nudgeTime = ReminderSchedulerService.calculateWindowNudgeTrigger(
        window: TimeWindow.morning,
        settings: settings,
        now: now,
      );

      expect(nudgeTime, DateTime(2026, 8, 15, 11, 30));
    });

    test('shouldTriggerWindowNudge is true only when pending items exist and time is future', () {
      final morningItems = [
        RoutineItem(
          id: 'item-1',
          title: 'Vitamins',
          category: 'MEDS',
          timeWindow: TimeWindow.morning,
          scheduledDate: '2026-08-15',
          status: ItemStatus.pending,
          updatedAt: now,
          createdAt: now,
        ),
      ];

      final shouldTrigger = ReminderSchedulerService.shouldTriggerWindowNudge(
        window: TimeWindow.morning,
        routinesInWindow: morningItems,
        settings: settings,
        now: now,
      );
      expect(shouldTrigger, true);

      final completedItems = [
        morningItems.first.copyWith(status: ItemStatus.completed),
      ];

      final shouldTriggerCompleted =
          ReminderSchedulerService.shouldTriggerWindowNudge(
            window: TimeWindow.morning,
            routinesInWindow: completedItems,
            settings: settings,
            now: now,
          );
      expect(shouldTriggerCompleted, false);
    });
  });
}
