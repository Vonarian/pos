class ReminderConfig {
  final bool enabled;
  final String time; // "HH:mm"
  final List<int> daysOfWeek; // 1 (Mon) .. 7 (Sun)
  final int snoozeMinutes;
  final DateTime? lastSnoozedUntil;

  const ReminderConfig({
    this.enabled = false,
    this.time = '08:00',
    this.daysOfWeek = const [],
    this.snoozeMinutes = 15,
    this.lastSnoozedUntil,
  });

  bool get isDaily => daysOfWeek.isEmpty || daysOfWeek.length == 7;

  bool isScheduledForDay(int weekday) {
    if (!enabled) return false;
    if (isDaily) return true;
    return daysOfWeek.contains(weekday);
  }

  factory ReminderConfig.fromJson(Map<String, dynamic> json) {
    return ReminderConfig(
      enabled: json['enabled'] as bool? ?? false,
      time: json['time'] as String? ?? '08:00',
      daysOfWeek:
          (json['days_of_week'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
      snoozeMinutes: json['snooze_minutes'] as int? ?? 15,
      lastSnoozedUntil:
          json['last_snoozed_until'] != null
              ? DateTime.parse(json['last_snoozed_until'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'time': time,
    'days_of_week': daysOfWeek,
    'snooze_minutes': snoozeMinutes,
    if (lastSnoozedUntil != null)
      'last_snoozed_until': lastSnoozedUntil!.toIso8601String(),
  };

  ReminderConfig copyWith({
    bool? enabled,
    String? time,
    List<int>? daysOfWeek,
    int? snoozeMinutes,
    DateTime? lastSnoozedUntil,
  }) {
    return ReminderConfig(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      lastSnoozedUntil: lastSnoozedUntil ?? this.lastSnoozedUntil,
    );
  }
}
