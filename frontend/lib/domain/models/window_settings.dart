import 'routine_item.dart';

class WindowSettings {
  final int morningStartHour;
  final int morningEndHour;
  final int afternoonStartHour;
  final int afternoonEndHour;
  final int eveningStartHour;
  final int eveningEndHour;
  final int nightStartHour;
  final int nightEndHour;
  final int nudgeLeadMinutes;
  final bool windowNudgesEnabled;

  const WindowSettings({
    required this.morningStartHour,
    required this.morningEndHour,
    required this.afternoonStartHour,
    required this.afternoonEndHour,
    required this.eveningStartHour,
    required this.eveningEndHour,
    required this.nightStartHour,
    required this.nightEndHour,
    this.nudgeLeadMinutes = 30,
    this.windowNudgesEnabled = true,
  });

  factory WindowSettings.defaults() => const WindowSettings(
    morningStartHour: 6,
    morningEndHour: 12,
    afternoonStartHour: 12,
    afternoonEndHour: 18,
    eveningStartHour: 18,
    eveningEndHour: 21,
    nightStartHour: 21,
    nightEndHour: 6,
    nudgeLeadMinutes: 30,
    windowNudgesEnabled: true,
  );

  TimeWindow calculateWindow(DateTime time) {
    final hour = time.hour;
    if (hour >= morningStartHour && hour < morningEndHour) {
      return TimeWindow.morning;
    }
    if (hour >= afternoonStartHour && hour < afternoonEndHour) {
      return TimeWindow.afternoon;
    }
    if (hour >= eveningStartHour && hour < eveningEndHour) {
      return TimeWindow.evening;
    }
    return TimeWindow.night;
  }

  DateTime getClosingTime(DateTime baseDate, TimeWindow window) {
    switch (window) {
      case TimeWindow.morning:
        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          morningEndHour,
          0,
        );
      case TimeWindow.afternoon:
        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          afternoonEndHour,
          0,
        );
      case TimeWindow.evening:
        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          eveningEndHour,
          0,
        );
      case TimeWindow.night:
        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          nightEndHour,
          0,
        ).add(const Duration(days: 1));
    }
  }

  factory WindowSettings.fromJson(Map<String, dynamic> json) => WindowSettings(
    morningStartHour: json['morning_start'] as int? ?? 6,
    morningEndHour: json['morning_end'] as int? ?? 12,
    afternoonStartHour: json['afternoon_start'] as int? ?? 12,
    afternoonEndHour: json['afternoon_end'] as int? ?? 18,
    eveningStartHour: json['evening_start'] as int? ?? 18,
    eveningEndHour: json['evening_end'] as int? ?? 21,
    nightStartHour: json['night_start'] as int? ?? 21,
    nightEndHour: json['night_end'] as int? ?? 6,
    nudgeLeadMinutes: json['nudge_lead_minutes'] as int? ?? 30,
    windowNudgesEnabled: json['window_nudges_enabled'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'morning_start': morningStartHour,
    'morning_end': morningEndHour,
    'afternoon_start': afternoonStartHour,
    'afternoon_end': afternoonEndHour,
    'evening_start': eveningStartHour,
    'evening_end': eveningEndHour,
    'night_start': nightStartHour,
    'night_end': nightEndHour,
    'nudge_lead_minutes': nudgeLeadMinutes,
    'window_nudges_enabled': windowNudgesEnabled,
  };
}
