import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/data/native/notification_service.dart';
import 'package:pos_frontend/domain/models/routine_item.dart';

void main() {
  group('NativeNotificationService', () {
    test('constants are correctly defined', () {
      expect(NativeNotificationService.habitChannelId, 'pos_habit_reminders');
      expect(
        NativeNotificationService.habitChannelName,
        'Habit & Medication Reminders',
      );
      expect(NativeNotificationService.windowChannelId, 'pos_window_nudges');
      expect(
        NativeNotificationService.windowChannelName,
        'Time Window Closing Alerts',
      );

      expect(NativeNotificationService.actionDone, 'ACTION_DONE');
      expect(NativeNotificationService.actionSnooze, 'ACTION_SNOOZE');
      expect(NativeNotificationService.actionSkip, 'ACTION_SKIP');
    });

    test('getNotificationIdForRoutine generates stable non-negative 32-bit int', () {
      const id1 = '01914ec7-4402-7c9e-9d22-8d76dfb4c2b9';
      const id2 = '01914ec7-4402-7c9e-9d22-8d76dfb4c2b0';

      final hash1 = NativeNotificationService.getNotificationIdForRoutine(id1);
      final hash2 = NativeNotificationService.getNotificationIdForRoutine(id2);

      expect(hash1, isNonNegative);
      expect(hash2, isNonNegative);
      expect(hash1, isNot(equals(hash2)));

      // Stable
      expect(
        NativeNotificationService.getNotificationIdForRoutine(id1),
        equals(hash1),
      );
    });

    test('getNotificationIdForWindow is distinct for each time window', () {
      final morning = NativeNotificationService.getNotificationIdForWindow(
        TimeWindow.morning,
      );
      final afternoon = NativeNotificationService.getNotificationIdForWindow(
        TimeWindow.afternoon,
      );
      final evening = NativeNotificationService.getNotificationIdForWindow(
        TimeWindow.evening,
      );
      final night = NativeNotificationService.getNotificationIdForWindow(
        TimeWindow.night,
      );

      final set = {morning, afternoon, evening, night};
      expect(set.length, 4);
    });

    test('buildPayload returns valid json map string', () {
      final payload = NativeNotificationService.buildPayload(
        routineId: 'test-123',
        title: 'Creatine 5g',
        snoozeMinutes: 15,
      );

      expect(payload, contains('"routineId":"test-123"'));
      expect(payload, contains('"title":"Creatine 5g"'));
      expect(payload, contains('"snoozeMinutes":15'));
    });
  });
}
