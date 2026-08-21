import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/domain/models/reminder_config.dart';

void main() {
  group('ReminderConfig', () {
    test('default constructor provides sensible defaults', () {
      const config = ReminderConfig();
      expect(config.enabled, false);
      expect(config.isRecurring, false);
      expect(config.time, '08:00');
      expect(config.daysOfWeek, isEmpty);
      expect(config.snoozeMinutes, 15);
      expect(config.isDaily, false);
      expect(config.isOneTime, true);
    });

    test('isScheduledForDay returns true for daily or matching day', () {
      const daily = ReminderConfig(enabled: true, isRecurring: true, daysOfWeek: []);
      expect(daily.isDaily, true);
      expect(daily.isScheduledForDay(DateTime.monday), true);
      expect(daily.isScheduledForDay(DateTime.sunday), true);

      const weekdays = ReminderConfig(
        enabled: true,
        isRecurring: true,
        daysOfWeek: [1, 2, 3, 4, 5],
      );
      expect(weekdays.isScheduledForDay(DateTime.wednesday), true);
      expect(weekdays.isScheduledForDay(DateTime.saturday), false);

      const disabled = ReminderConfig(enabled: false);
      expect(disabled.isScheduledForDay(DateTime.monday), false);
    });

    test('json serialization roundtrip', () {
      final config = ReminderConfig(
        enabled: true,
        time: '09:30',
        daysOfWeek: const [1, 3, 5],
        snoozeMinutes: 10,
        lastSnoozedUntil: DateTime(2026, 8, 15, 9, 40),
      );
      final json = config.toJson();
      final parsed = ReminderConfig.fromJson(json);
      expect(parsed.enabled, config.enabled);
      expect(parsed.time, config.time);
      expect(parsed.daysOfWeek, [1, 3, 5]);
      expect(parsed.snoozeMinutes, 10);
      expect(parsed.lastSnoozedUntil, config.lastSnoozedUntil);
    });

    test('isRecurring and isOneTime getters behave as expected', () {
      const oneTime = ReminderConfig(isRecurring: false);
      expect(oneTime.isRecurring, false);
      expect(oneTime.isOneTime, true);

      const recurring = ReminderConfig(isRecurring: true);
      expect(recurring.isRecurring, true);
      expect(recurring.isOneTime, false);
    });

    test('isScheduledForDay returns true for one-time reminders when enabled', () {
      const oneTime = ReminderConfig(
        enabled: true,
        isRecurring: false,
        daysOfWeek: [1], // Even if daysOfWeek is set, oneTime is scheduled on target date
      );
      expect(oneTime.isScheduledForDay(DateTime.sunday), true);
      expect(oneTime.isScheduledForDay(DateTime.friday), true);
    });

    test('json serialization roundtrip preserves isRecurring', () {
      final config = ReminderConfig(
        enabled: true,
        isRecurring: false,
        time: '21:00',
        daysOfWeek: const [],
        snoozeMinutes: 10,
        lastSnoozedUntil: DateTime(2026, 8, 15, 21, 10),
      );
      final json = config.toJson();
      final parsed = ReminderConfig.fromJson(json);
      expect(parsed.enabled, config.enabled);
      expect(parsed.isRecurring, false);
      expect(parsed.time, '21:00');
      expect(parsed.isOneTime, true);
    });

    test('copyWith updates specified fields correctly', () {
      const config = ReminderConfig(enabled: false, time: '08:00', isRecurring: false);
      final updated = config.copyWith(enabled: true, time: '09:00', isRecurring: true);
      expect(updated.enabled, true);
      expect(updated.time, '09:00');
      expect(updated.isRecurring, true);
      expect(updated.snoozeMinutes, 15);
    });
  });
}

