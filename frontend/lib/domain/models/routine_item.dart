enum ItemStatus {
  pending('PENDING'),
  completed('COMPLETED'),
  skipped('SKIPPED'),
  missed('MISSED');

  final String value;
  const ItemStatus(this.value);

  static ItemStatus fromString(String val) {
    return ItemStatus.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => ItemStatus.pending,
    );
  }
}

enum TimeWindow {
  morning('MORNING'),
  afternoon('AFTERNOON'),
  evening('EVENING'),
  night('NIGHT');

  final String value;
  const TimeWindow(this.value);

  static TimeWindow fromString(String val) {
    return TimeWindow.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => TimeWindow.morning,
    );
  }
}

class RoutineItem {
  final String id;
  final String? templateId;
  final String title;
  final String category;
  final TimeWindow timeWindow;
  final String scheduledDate; // YYYY-MM-DD
  final ItemStatus status;
  final DateTime? completedAt;
  final Map<String, dynamic> metadata;
  final DateTime updatedAt;
  final DateTime createdAt;

  const RoutineItem({
    required this.id,
    this.templateId,
    required this.title,
    required this.category,
    required this.timeWindow,
    required this.scheduledDate,
    required this.status,
    this.completedAt,
    this.metadata = const {},
    required this.updatedAt,
    required this.createdAt,
  });

  factory RoutineItem.fromJson(Map<String, dynamic> json) {
    return RoutineItem(
      id: json['id'] as String,
      templateId: json['template_id'] as String?,
      title: json['title'] as String,
      category: json['category'] as String,
      timeWindow: TimeWindow.fromString(json['time_window'] as String? ?? 'MORNING'),
      scheduledDate: json['scheduled_date'] as String,
      status: ItemStatus.fromString(json['status'] as String? ?? 'PENDING'),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (templateId != null) 'template_id': templateId,
      'title': title,
      'category': category,
      'time_window': timeWindow.value,
      'scheduled_date': scheduledDate,
      'status': status.value,
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      'metadata': metadata,
      'updated_at': updatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  RoutineItem copyWith({
    String? id,
    String? templateId,
    String? title,
    String? category,
    TimeWindow? timeWindow,
    String? scheduledDate,
    ItemStatus? status,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return RoutineItem(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      category: category ?? this.category,
      timeWindow: timeWindow ?? this.timeWindow,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
