// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RoutineItemsTableTable extends RoutineItemsTable
    with TableInfo<$RoutineItemsTableTable, RoutineItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutineItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _templateIdMeta =
      const VerificationMeta('templateId');
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
      'template_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timeWindowMeta =
      const VerificationMeta('timeWindow');
  @override
  late final GeneratedColumn<String> timeWindow = GeneratedColumn<String>(
      'time_window', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scheduledDateMeta =
      const VerificationMeta('scheduledDate');
  @override
  late final GeneratedColumn<String> scheduledDate = GeneratedColumn<String>(
      'scheduled_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('PENDING'));
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _metadataJsonMeta =
      const VerificationMeta('metadataJson');
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
      'metadata_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        templateId,
        title,
        category,
        timeWindow,
        scheduledDate,
        status,
        completedAt,
        metadataJson,
        updatedAt,
        createdAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routine_items_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<RoutineItemsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
          _templateIdMeta,
          templateId.isAcceptableOrUnknown(
              data['template_id']!, _templateIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('time_window')) {
      context.handle(
          _timeWindowMeta,
          timeWindow.isAcceptableOrUnknown(
              data['time_window']!, _timeWindowMeta));
    } else if (isInserting) {
      context.missing(_timeWindowMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
          _scheduledDateMeta,
          scheduledDate.isAcceptableOrUnknown(
              data['scheduled_date']!, _scheduledDateMeta));
    } else if (isInserting) {
      context.missing(_scheduledDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
          _metadataJsonMeta,
          metadataJson.isAcceptableOrUnknown(
              data['metadata_json']!, _metadataJsonMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoutineItemsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineItemsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      templateId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}template_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      timeWindow: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}time_window'])!,
      scheduledDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scheduled_date'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      metadataJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata_json'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $RoutineItemsTableTable createAlias(String alias) {
    return $RoutineItemsTableTable(attachedDatabase, alias);
  }
}

class RoutineItemsTableData extends DataClass
    implements Insertable<RoutineItemsTableData> {
  final String id;
  final String? templateId;
  final String title;
  final String category;
  final String timeWindow;
  final String scheduledDate;
  final String status;
  final DateTime? completedAt;
  final String metadataJson;
  final DateTime updatedAt;
  final DateTime createdAt;
  final bool isSynced;
  const RoutineItemsTableData(
      {required this.id,
      this.templateId,
      required this.title,
      required this.category,
      required this.timeWindow,
      required this.scheduledDate,
      required this.status,
      this.completedAt,
      required this.metadataJson,
      required this.updatedAt,
      required this.createdAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['time_window'] = Variable<String>(timeWindow);
    map['scheduled_date'] = Variable<String>(scheduledDate);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['metadata_json'] = Variable<String>(metadataJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  RoutineItemsTableCompanion toCompanion(bool nullToAbsent) {
    return RoutineItemsTableCompanion(
      id: Value(id),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      title: Value(title),
      category: Value(category),
      timeWindow: Value(timeWindow),
      scheduledDate: Value(scheduledDate),
      status: Value(status),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      metadataJson: Value(metadataJson),
      updatedAt: Value(updatedAt),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory RoutineItemsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineItemsTableData(
      id: serializer.fromJson<String>(json['id']),
      templateId: serializer.fromJson<String?>(json['templateId']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      timeWindow: serializer.fromJson<String>(json['timeWindow']),
      scheduledDate: serializer.fromJson<String>(json['scheduledDate']),
      status: serializer.fromJson<String>(json['status']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateId': serializer.toJson<String?>(templateId),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'timeWindow': serializer.toJson<String>(timeWindow),
      'scheduledDate': serializer.toJson<String>(scheduledDate),
      'status': serializer.toJson<String>(status),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'metadataJson': serializer.toJson<String>(metadataJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  RoutineItemsTableData copyWith(
          {String? id,
          Value<String?> templateId = const Value.absent(),
          String? title,
          String? category,
          String? timeWindow,
          String? scheduledDate,
          String? status,
          Value<DateTime?> completedAt = const Value.absent(),
          String? metadataJson,
          DateTime? updatedAt,
          DateTime? createdAt,
          bool? isSynced}) =>
      RoutineItemsTableData(
        id: id ?? this.id,
        templateId: templateId.present ? templateId.value : this.templateId,
        title: title ?? this.title,
        category: category ?? this.category,
        timeWindow: timeWindow ?? this.timeWindow,
        scheduledDate: scheduledDate ?? this.scheduledDate,
        status: status ?? this.status,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        metadataJson: metadataJson ?? this.metadataJson,
        updatedAt: updatedAt ?? this.updatedAt,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
  RoutineItemsTableData copyWithCompanion(RoutineItemsTableCompanion data) {
    return RoutineItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      templateId:
          data.templateId.present ? data.templateId.value : this.templateId,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      timeWindow:
          data.timeWindow.present ? data.timeWindow.value : this.timeWindow,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      status: data.status.present ? data.status.value : this.status,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineItemsTableData(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('timeWindow: $timeWindow, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      templateId,
      title,
      category,
      timeWindow,
      scheduledDate,
      status,
      completedAt,
      metadataJson,
      updatedAt,
      createdAt,
      isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineItemsTableData &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.title == this.title &&
          other.category == this.category &&
          other.timeWindow == this.timeWindow &&
          other.scheduledDate == this.scheduledDate &&
          other.status == this.status &&
          other.completedAt == this.completedAt &&
          other.metadataJson == this.metadataJson &&
          other.updatedAt == this.updatedAt &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class RoutineItemsTableCompanion
    extends UpdateCompanion<RoutineItemsTableData> {
  final Value<String> id;
  final Value<String?> templateId;
  final Value<String> title;
  final Value<String> category;
  final Value<String> timeWindow;
  final Value<String> scheduledDate;
  final Value<String> status;
  final Value<DateTime?> completedAt;
  final Value<String> metadataJson;
  final Value<DateTime> updatedAt;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const RoutineItemsTableCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.timeWindow = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutineItemsTableCompanion.insert({
    required String id,
    this.templateId = const Value.absent(),
    required String title,
    required String category,
    required String timeWindow,
    required String scheduledDate,
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.metadataJson = const Value.absent(),
    required DateTime updatedAt,
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        category = Value(category),
        timeWindow = Value(timeWindow),
        scheduledDate = Value(scheduledDate),
        updatedAt = Value(updatedAt),
        createdAt = Value(createdAt);
  static Insertable<RoutineItemsTableData> custom({
    Expression<String>? id,
    Expression<String>? templateId,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? timeWindow,
    Expression<String>? scheduledDate,
    Expression<String>? status,
    Expression<DateTime>? completedAt,
    Expression<String>? metadataJson,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (timeWindow != null) 'time_window': timeWindow,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (status != null) 'status': status,
      if (completedAt != null) 'completed_at': completedAt,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutineItemsTableCompanion copyWith(
      {Value<String>? id,
      Value<String?>? templateId,
      Value<String>? title,
      Value<String>? category,
      Value<String>? timeWindow,
      Value<String>? scheduledDate,
      Value<String>? status,
      Value<DateTime?>? completedAt,
      Value<String>? metadataJson,
      Value<DateTime>? updatedAt,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return RoutineItemsTableCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      category: category ?? this.category,
      timeWindow: timeWindow ?? this.timeWindow,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      metadataJson: metadataJson ?? this.metadataJson,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (timeWindow.present) {
      map['time_window'] = Variable<String>(timeWindow.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<String>(scheduledDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutineItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('timeWindow: $timeWindow, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HealthMetricsTableTable extends HealthMetricsTable
    with TableInfo<$HealthMetricsTableTable, HealthMetricsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthMetricsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _metricMeta = const VerificationMeta('metric');
  @override
  late final GeneratedColumn<String> metric = GeneratedColumn<String>(
      'metric', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _externalIdMeta =
      const VerificationMeta('externalId');
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
      'external_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        source,
        metric,
        value,
        unit,
        startTime,
        endTime,
        externalId,
        syncedAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_metrics_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<HealthMetricsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('metric')) {
      context.handle(_metricMeta,
          metric.isAcceptableOrUnknown(data['metric']!, _metricMeta));
    } else if (isInserting) {
      context.missing(_metricMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
          _externalIdMeta,
          externalId.isAcceptableOrUnknown(
              data['external_id']!, _externalIdMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HealthMetricsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthMetricsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      metric: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metric'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time'])!,
      externalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}external_id']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $HealthMetricsTableTable createAlias(String alias) {
    return $HealthMetricsTableTable(attachedDatabase, alias);
  }
}

class HealthMetricsTableData extends DataClass
    implements Insertable<HealthMetricsTableData> {
  final String id;
  final String source;
  final String metric;
  final double value;
  final String unit;
  final DateTime startTime;
  final DateTime endTime;
  final String? externalId;
  final DateTime syncedAt;
  final bool isSynced;
  const HealthMetricsTableData(
      {required this.id,
      required this.source,
      required this.metric,
      required this.value,
      required this.unit,
      required this.startTime,
      required this.endTime,
      this.externalId,
      required this.syncedAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source'] = Variable<String>(source);
    map['metric'] = Variable<String>(metric);
    map['value'] = Variable<double>(value);
    map['unit'] = Variable<String>(unit);
    map['start_time'] = Variable<DateTime>(startTime);
    map['end_time'] = Variable<DateTime>(endTime);
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  HealthMetricsTableCompanion toCompanion(bool nullToAbsent) {
    return HealthMetricsTableCompanion(
      id: Value(id),
      source: Value(source),
      metric: Value(metric),
      value: Value(value),
      unit: Value(unit),
      startTime: Value(startTime),
      endTime: Value(endTime),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      syncedAt: Value(syncedAt),
      isSynced: Value(isSynced),
    );
  }

  factory HealthMetricsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthMetricsTableData(
      id: serializer.fromJson<String>(json['id']),
      source: serializer.fromJson<String>(json['source']),
      metric: serializer.fromJson<String>(json['metric']),
      value: serializer.fromJson<double>(json['value']),
      unit: serializer.fromJson<String>(json['unit']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime>(json['endTime']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'source': serializer.toJson<String>(source),
      'metric': serializer.toJson<String>(metric),
      'value': serializer.toJson<double>(value),
      'unit': serializer.toJson<String>(unit),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime>(endTime),
      'externalId': serializer.toJson<String?>(externalId),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  HealthMetricsTableData copyWith(
          {String? id,
          String? source,
          String? metric,
          double? value,
          String? unit,
          DateTime? startTime,
          DateTime? endTime,
          Value<String?> externalId = const Value.absent(),
          DateTime? syncedAt,
          bool? isSynced}) =>
      HealthMetricsTableData(
        id: id ?? this.id,
        source: source ?? this.source,
        metric: metric ?? this.metric,
        value: value ?? this.value,
        unit: unit ?? this.unit,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        externalId: externalId.present ? externalId.value : this.externalId,
        syncedAt: syncedAt ?? this.syncedAt,
        isSynced: isSynced ?? this.isSynced,
      );
  HealthMetricsTableData copyWithCompanion(HealthMetricsTableCompanion data) {
    return HealthMetricsTableData(
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      metric: data.metric.present ? data.metric.value : this.metric,
      value: data.value.present ? data.value.value : this.value,
      unit: data.unit.present ? data.unit.value : this.unit,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      externalId:
          data.externalId.present ? data.externalId.value : this.externalId,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthMetricsTableData(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('metric: $metric, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('externalId: $externalId, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, source, metric, value, unit, startTime,
      endTime, externalId, syncedAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthMetricsTableData &&
          other.id == this.id &&
          other.source == this.source &&
          other.metric == this.metric &&
          other.value == this.value &&
          other.unit == this.unit &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.externalId == this.externalId &&
          other.syncedAt == this.syncedAt &&
          other.isSynced == this.isSynced);
}

class HealthMetricsTableCompanion
    extends UpdateCompanion<HealthMetricsTableData> {
  final Value<String> id;
  final Value<String> source;
  final Value<String> metric;
  final Value<double> value;
  final Value<String> unit;
  final Value<DateTime> startTime;
  final Value<DateTime> endTime;
  final Value<String?> externalId;
  final Value<DateTime> syncedAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const HealthMetricsTableCompanion({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.metric = const Value.absent(),
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.externalId = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HealthMetricsTableCompanion.insert({
    required String id,
    required String source,
    required String metric,
    required double value,
    required String unit,
    required DateTime startTime,
    required DateTime endTime,
    this.externalId = const Value.absent(),
    required DateTime syncedAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        source = Value(source),
        metric = Value(metric),
        value = Value(value),
        unit = Value(unit),
        startTime = Value(startTime),
        endTime = Value(endTime),
        syncedAt = Value(syncedAt);
  static Insertable<HealthMetricsTableData> custom({
    Expression<String>? id,
    Expression<String>? source,
    Expression<String>? metric,
    Expression<double>? value,
    Expression<String>? unit,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<String>? externalId,
    Expression<DateTime>? syncedAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (metric != null) 'metric': metric,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (externalId != null) 'external_id': externalId,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HealthMetricsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? source,
      Value<String>? metric,
      Value<double>? value,
      Value<String>? unit,
      Value<DateTime>? startTime,
      Value<DateTime>? endTime,
      Value<String?>? externalId,
      Value<DateTime>? syncedAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return HealthMetricsTableCompanion(
      id: id ?? this.id,
      source: source ?? this.source,
      metric: metric ?? this.metric,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      externalId: externalId ?? this.externalId,
      syncedAt: syncedAt ?? this.syncedAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (metric.present) {
      map['metric'] = Variable<String>(metric.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthMetricsTableCompanion(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('metric: $metric, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('externalId: $externalId, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RoutineItemsTableTable routineItemsTable =
      $RoutineItemsTableTable(this);
  late final $HealthMetricsTableTable healthMetricsTable =
      $HealthMetricsTableTable(this);
  late final RoutineDao routineDao = RoutineDao(this as AppDatabase);
  late final MetricDao metricDao = MetricDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [routineItemsTable, healthMetricsTable];
}

typedef $$RoutineItemsTableTableCreateCompanionBuilder
    = RoutineItemsTableCompanion Function({
  required String id,
  Value<String?> templateId,
  required String title,
  required String category,
  required String timeWindow,
  required String scheduledDate,
  Value<String> status,
  Value<DateTime?> completedAt,
  Value<String> metadataJson,
  required DateTime updatedAt,
  required DateTime createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$RoutineItemsTableTableUpdateCompanionBuilder
    = RoutineItemsTableCompanion Function({
  Value<String> id,
  Value<String?> templateId,
  Value<String> title,
  Value<String> category,
  Value<String> timeWindow,
  Value<String> scheduledDate,
  Value<String> status,
  Value<DateTime?> completedAt,
  Value<String> metadataJson,
  Value<DateTime> updatedAt,
  Value<DateTime> createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$RoutineItemsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RoutineItemsTableTable,
    RoutineItemsTableData,
    $$RoutineItemsTableTableFilterComposer,
    $$RoutineItemsTableTableOrderingComposer,
    $$RoutineItemsTableTableCreateCompanionBuilder,
    $$RoutineItemsTableTableUpdateCompanionBuilder> {
  $$RoutineItemsTableTableTableManager(
      _$AppDatabase db, $RoutineItemsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$RoutineItemsTableTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$RoutineItemsTableTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> templateId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> timeWindow = const Value.absent(),
            Value<String> scheduledDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String> metadataJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutineItemsTableCompanion(
            id: id,
            templateId: templateId,
            title: title,
            category: category,
            timeWindow: timeWindow,
            scheduledDate: scheduledDate,
            status: status,
            completedAt: completedAt,
            metadataJson: metadataJson,
            updatedAt: updatedAt,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> templateId = const Value.absent(),
            required String title,
            required String category,
            required String timeWindow,
            required String scheduledDate,
            Value<String> status = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String> metadataJson = const Value.absent(),
            required DateTime updatedAt,
            required DateTime createdAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutineItemsTableCompanion.insert(
            id: id,
            templateId: templateId,
            title: title,
            category: category,
            timeWindow: timeWindow,
            scheduledDate: scheduledDate,
            status: status,
            completedAt: completedAt,
            metadataJson: metadataJson,
            updatedAt: updatedAt,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
        ));
}

class $$RoutineItemsTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $RoutineItemsTableTable> {
  $$RoutineItemsTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get templateId => $state.composableBuilder(
      column: $state.table.templateId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get timeWindow => $state.composableBuilder(
      column: $state.table.timeWindow,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get scheduledDate => $state.composableBuilder(
      column: $state.table.scheduledDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get completedAt => $state.composableBuilder(
      column: $state.table.completedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get metadataJson => $state.composableBuilder(
      column: $state.table.metadataJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$RoutineItemsTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $RoutineItemsTableTable> {
  $$RoutineItemsTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get templateId => $state.composableBuilder(
      column: $state.table.templateId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get timeWindow => $state.composableBuilder(
      column: $state.table.timeWindow,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get scheduledDate => $state.composableBuilder(
      column: $state.table.scheduledDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get completedAt => $state.composableBuilder(
      column: $state.table.completedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get metadataJson => $state.composableBuilder(
      column: $state.table.metadataJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$HealthMetricsTableTableCreateCompanionBuilder
    = HealthMetricsTableCompanion Function({
  required String id,
  required String source,
  required String metric,
  required double value,
  required String unit,
  required DateTime startTime,
  required DateTime endTime,
  Value<String?> externalId,
  required DateTime syncedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$HealthMetricsTableTableUpdateCompanionBuilder
    = HealthMetricsTableCompanion Function({
  Value<String> id,
  Value<String> source,
  Value<String> metric,
  Value<double> value,
  Value<String> unit,
  Value<DateTime> startTime,
  Value<DateTime> endTime,
  Value<String?> externalId,
  Value<DateTime> syncedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$HealthMetricsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HealthMetricsTableTable,
    HealthMetricsTableData,
    $$HealthMetricsTableTableFilterComposer,
    $$HealthMetricsTableTableOrderingComposer,
    $$HealthMetricsTableTableCreateCompanionBuilder,
    $$HealthMetricsTableTableUpdateCompanionBuilder> {
  $$HealthMetricsTableTableTableManager(
      _$AppDatabase db, $HealthMetricsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$HealthMetricsTableTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$HealthMetricsTableTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> metric = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime> endTime = const Value.absent(),
            Value<String?> externalId = const Value.absent(),
            Value<DateTime> syncedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HealthMetricsTableCompanion(
            id: id,
            source: source,
            metric: metric,
            value: value,
            unit: unit,
            startTime: startTime,
            endTime: endTime,
            externalId: externalId,
            syncedAt: syncedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String source,
            required String metric,
            required double value,
            required String unit,
            required DateTime startTime,
            required DateTime endTime,
            Value<String?> externalId = const Value.absent(),
            required DateTime syncedAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HealthMetricsTableCompanion.insert(
            id: id,
            source: source,
            metric: metric,
            value: value,
            unit: unit,
            startTime: startTime,
            endTime: endTime,
            externalId: externalId,
            syncedAt: syncedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
        ));
}

class $$HealthMetricsTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $HealthMetricsTableTable> {
  $$HealthMetricsTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get source => $state.composableBuilder(
      column: $state.table.source,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get metric => $state.composableBuilder(
      column: $state.table.metric,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get unit => $state.composableBuilder(
      column: $state.table.unit,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get startTime => $state.composableBuilder(
      column: $state.table.startTime,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get endTime => $state.composableBuilder(
      column: $state.table.endTime,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get externalId => $state.composableBuilder(
      column: $state.table.externalId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get syncedAt => $state.composableBuilder(
      column: $state.table.syncedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$HealthMetricsTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $HealthMetricsTableTable> {
  $$HealthMetricsTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get source => $state.composableBuilder(
      column: $state.table.source,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get metric => $state.composableBuilder(
      column: $state.table.metric,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get unit => $state.composableBuilder(
      column: $state.table.unit,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get startTime => $state.composableBuilder(
      column: $state.table.startTime,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get endTime => $state.composableBuilder(
      column: $state.table.endTime,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get externalId => $state.composableBuilder(
      column: $state.table.externalId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get syncedAt => $state.composableBuilder(
      column: $state.table.syncedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RoutineItemsTableTableTableManager get routineItemsTable =>
      $$RoutineItemsTableTableTableManager(_db, _db.routineItemsTable);
  $$HealthMetricsTableTableTableManager get healthMetricsTable =>
      $$HealthMetricsTableTableTableManager(_db, _db.healthMetricsTable);
}
