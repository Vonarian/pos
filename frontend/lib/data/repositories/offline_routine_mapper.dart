import 'dart:convert';
import 'package:drift/drift.dart';
import '../local/database.dart';
import '../../domain/models/routine_item.dart';

class OfflineRoutineMapper {
  static RoutineItem mapRowToDomain(RoutineItemsTableData row) {
    Map<String, dynamic> meta = {};
    try {
      meta = jsonDecode(row.metadataJson) as Map<String, dynamic>;
    } catch (_) {}

    return RoutineItem(
      id: row.id,
      templateId: row.templateId,
      title: row.title,
      category: row.category,
      timeWindow: TimeWindow.fromString(row.timeWindow),
      scheduledDate: row.scheduledDate,
      status: ItemStatus.fromString(row.status),
      completedAt: row.completedAt,
      metadata: meta,
      updatedAt: row.updatedAt,
      createdAt: row.createdAt,
    );
  }

  static RoutineItemsTableCompanion mapDomainToCompanion(
    RoutineItem item, {
    bool isSynced = false,
  }) {
    return RoutineItemsTableCompanion.insert(
      id: item.id,
      templateId: Value(item.templateId),
      title: item.title,
      category: item.category,
      timeWindow: item.timeWindow.value,
      scheduledDate: item.scheduledDate,
      status: Value(item.status.value),
      completedAt: Value(item.completedAt),
      metadataJson: Value(jsonEncode(item.metadata)),
      updatedAt: item.updatedAt,
      createdAt: item.createdAt,
      isSynced: Value(isSynced),
    );
  }
}
