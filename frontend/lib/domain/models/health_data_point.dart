enum MetricType {
  steps('STEPS'),
  caloriesBurned('CALORIES_BURNED'),
  sleepDuration('SLEEP_DURATION'),
  weight('WEIGHT'),
  bodyFat('BODY_FAT'),
  workoutSession('WORKOUT_SESSION'),
  waterIntake('WATER_INTAKE');

  final String value;
  const MetricType(this.value);

  static MetricType fromString(String val) {
    return MetricType.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => MetricType.steps,
    );
  }
}

class HealthDataPoint {
  final String id;
  final String source;
  final MetricType metric;
  final double value;
  final String unit;
  final DateTime startTime;
  final DateTime endTime;
  final String? externalId;
  final DateTime syncedAt;

  const HealthDataPoint({
    required this.id,
    required this.source,
    required this.metric,
    required this.value,
    required this.unit,
    required this.startTime,
    required this.endTime,
    this.externalId,
    required this.syncedAt,
  });

  factory HealthDataPoint.fromJson(Map<String, dynamic> json) {
    return HealthDataPoint(
      id: json['id'] as String,
      source: json['source'] as String,
      metric: MetricType.fromString(json['metric'] as String),
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      externalId: json['external_id'] as String?,
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'metric': metric.value,
      'value': value,
      'unit': unit,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      if (externalId != null) 'external_id': externalId,
      'synced_at': syncedAt.toIso8601String(),
    };
  }
}
