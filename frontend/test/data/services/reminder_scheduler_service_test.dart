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

    test('returns null if reminder is disabled or in the past', () {
      final disabledConfig = const ReminderConfig(
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

      final pastConfig = const ReminderConfig(enabled: true, time: '07:00');
      final pastItem = disabledItem.copyWith(
        metadata: {'reminder': pastConfig.toJson()},
      );

      expect(
        ReminderSchedulerService.calculateReminderTrigger(
          item: pastItem,
          now: now,
        ),
        isNull,
      );
    });

    test('returns null if reminder is not scheduled for today weekday', () {
      // 2026-08-15 is Saturday (weekday = 6)
      final weekdaysOnlyConfig = const ReminderConfig(
        enabled: true,
        time: '09:30',
        daysOfWeek: [1, 2, 3, 4, 5],
      );

      final item = RoutineItem(
        id: 'habit-3',
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
        ReminderSchedulerService.calculateReminderTrigger(
          item: item,
          now: now,
        ),
        isNull,
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
