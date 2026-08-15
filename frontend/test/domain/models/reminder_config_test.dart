import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/domain/models/reminder_config.dart';

void main() {
  group('ReminderConfig', () {
    test('default constructor provides sensible defaults', () {
      const config = ReminderConfig();
      expect(config.enabled, false);
      expect(config.time, '08:00');
      expect(config.daysOfWeek, isEmpty);
      expect(config.snoozeMinutes, 15);
      expect(config.isDaily, true);
    });

    test('isScheduledForDay returns true for daily or matching day', () {
      const daily = ReminderConfig(enabled: true, daysOfWeek: []);
      expect(daily.isScheduledForDay(DateTime.monday), true);
      expect(daily.isScheduledForDay(DateTime.sunday), true);

      const weekdays = ReminderConfig(
        enabled: true,
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

    test('copyWith updates specified fields correctly', () {
      const config = ReminderConfig(enabled: false, time: '08:00');
      final updated = config.copyWith(enabled: true, time: '09:00');
      expect(updated.enabled, true);
      expect(updated.time, '09:00');
      expect(updated.snoozeMinutes, 15);
    });
  });
}
