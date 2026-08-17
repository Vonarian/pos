import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/domain/models/routine_item.dart';
import 'package:pos_frontend/domain/models/window_settings.dart';

void main() {
  group('WindowSettings', () {
    test('defaults match standard 4 quadrants', () {
      final settings = WindowSettings.defaults();
      expect(settings.morningStartHour, 6);
      expect(settings.morningEndHour, 12);
      expect(settings.afternoonStartHour, 12);
      expect(settings.afternoonEndHour, 18);
      expect(settings.eveningStartHour, 18);
      expect(settings.eveningEndHour, 21);
      expect(settings.nightStartHour, 21);
      expect(settings.nightEndHour, 6);
      expect(settings.nudgeLeadMinutes, 30);
      expect(settings.windowNudgesEnabled, true);
    });

    test('calculateWindow returns correct TimeWindow based on hours', () {
      final settings = WindowSettings.defaults();
      expect(
        settings.calculateWindow(DateTime(2026, 8, 15, 8, 0)),
        TimeWindow.morning,
      );
      expect(
        settings.calculateWindow(DateTime(2026, 8, 15, 14, 0)),
        TimeWindow.afternoon,
      );
      expect(
        settings.calculateWindow(DateTime(2026, 8, 15, 19, 30)),
        TimeWindow.evening,
      );
      expect(
        settings.calculateWindow(DateTime(2026, 8, 15, 23, 0)),
        TimeWindow.night,
      );
      expect(
        settings.calculateWindow(DateTime(2026, 8, 15, 4, 0)),
        TimeWindow.night,
      );
    });

    test('getClosingTime returns correct DateTime today', () {
      final settings = WindowSettings.defaults();
      final date = DateTime(2026, 8, 15);
      final morningClose = settings.getClosingTime(date, TimeWindow.morning);
      expect(morningClose, DateTime(2026, 8, 15, 12, 0));

      final afternoonClose = settings.getClosingTime(
        date,
        TimeWindow.afternoon,
      );
      expect(afternoonClose, DateTime(2026, 8, 15, 18, 0));

      final eveningClose = settings.getClosingTime(date, TimeWindow.evening);
      expect(eveningClose, DateTime(2026, 8, 15, 21, 0));

      final nightClose = settings.getClosingTime(date, TimeWindow.night);
      expect(nightClose, DateTime(2026, 8, 16, 6, 0));
    });

    test('json serialization roundtrip', () {
      const settings = WindowSettings(
        morningStartHour: 7,
        morningEndHour: 11,
        afternoonStartHour: 11,
        afternoonEndHour: 17,
        eveningStartHour: 17,
        eveningEndHour: 22,
        nightStartHour: 22,
        nightEndHour: 7,
        nudgeLeadMinutes: 45,
        windowNudgesEnabled: false,
      );

      final json = settings.toJson();
      final parsed = WindowSettings.fromJson(json);
      expect(parsed.morningStartHour, 7);
      expect(parsed.morningEndHour, 11);
      expect(parsed.afternoonStartHour, 11);
      expect(parsed.afternoonEndHour, 17);
      expect(parsed.eveningStartHour, 17);
      expect(parsed.eveningEndHour, 22);
      expect(parsed.nightStartHour, 22);
      expect(parsed.nightEndHour, 7);
      expect(parsed.nudgeLeadMinutes, 45);
      expect(parsed.windowNudgesEnabled, false);
    });
  });
}
