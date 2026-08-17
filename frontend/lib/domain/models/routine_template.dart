import 'reminder_config.dart';
import 'routine_item.dart';

class RoutineTemplate {
  final String id;
  final String title;
  final String category;
  final TimeWindow timeWindow;
  final List<int> daysOfWeek;
  final Map<String, dynamic> metadata;
  final bool isActive;
  final DateTime updatedAt;
  final DateTime createdAt;

  const RoutineTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.timeWindow,
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    this.metadata = const {},
    this.isActive = true,
    required this.updatedAt,
    required this.createdAt,
  });

  ReminderConfig? get reminderConfig {
    if (metadata['reminder'] != null &&
        metadata['reminder'] is Map<String, dynamic>) {
      return ReminderConfig.fromJson(
        metadata['reminder'] as Map<String, dynamic>,
      );
    }
    return null;
  }

  RoutineTemplate copyWith({
    String? id,
    String? title,
    String? category,
    TimeWindow? timeWindow,
    List<int>? daysOfWeek,
    Map<String, dynamic>? metadata,
    bool? isActive,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return RoutineTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      timeWindow: timeWindow ?? this.timeWindow,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory RoutineTemplate.fromJson(Map<String, dynamic> json) {
    List<int> days = const [1, 2, 3, 4, 5, 6, 7];
    if (json['days_of_week'] is List) {
      days = (json['days_of_week'] as List).map((e) => e as int).toList();
    }
    return RoutineTemplate(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      timeWindow: TimeWindow.fromString(json['time_window'] as String),
      daysOfWeek: days,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      isActive: (json['is_active'] as bool?) ?? true,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'time_window': timeWindow.value,
      'days_of_week': daysOfWeek,
      'metadata': metadata,
      'is_active': isActive,
      'updated_at': updatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
