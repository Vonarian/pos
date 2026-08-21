class ReminderConfig {
  final bool enabled;
  final bool isRecurring;
  final String time; // "HH:mm"
  final List<int> daysOfWeek; // 1 (Mon) .. 7 (Sun)
  final int snoozeMinutes;
  final DateTime? lastSnoozedUntil;

  const ReminderConfig({
    this.enabled = false,
    this.isRecurring = false,
    this.time = '08:00',
    this.daysOfWeek = const [],
    this.snoozeMinutes = 15,
    this.lastSnoozedUntil,
  });

  bool get isOneTime => !isRecurring;
  bool get isDaily => isRecurring && (daysOfWeek.isEmpty || daysOfWeek.length == 7);

  bool isScheduledForDay(int weekday) {
    if (!enabled) return false;
    if (isOneTime) return true;
    if (isDaily) return true;
    return daysOfWeek.contains(weekday);
  }

  factory ReminderConfig.fromJson(Map<String, dynamic> json) {
    final days = (json['days_of_week'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ??
        const [];
    return ReminderConfig(
      enabled: json['enabled'] as bool? ?? false,
      isRecurring: json['is_recurring'] as bool? ?? days.isNotEmpty,
      time: json['time'] as String? ?? '08:00',
      daysOfWeek: days,
      snoozeMinutes: json['snooze_minutes'] as int? ?? 15,
      lastSnoozedUntil: json['last_snoozed_until'] != null
          ? DateTime.parse(json['last_snoozed_until'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'is_recurring': isRecurring,
    'time': time,
    'days_of_week': daysOfWeek,
    'snooze_minutes': snoozeMinutes,
    if (lastSnoozedUntil != null)
      'last_snoozed_until': lastSnoozedUntil!.toIso8601String(),
  };

  ReminderConfig copyWith({
    bool? enabled,
    bool? isRecurring,
    String? time,
    List<int>? daysOfWeek,
    int? snoozeMinutes,
    DateTime? lastSnoozedUntil,
  }) {
    return ReminderConfig(
      enabled: enabled ?? this.enabled,
      isRecurring: isRecurring ?? this.isRecurring,
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      lastSnoozedUntil: lastSnoozedUntil ?? this.lastSnoozedUntil,
    );
  }
}
