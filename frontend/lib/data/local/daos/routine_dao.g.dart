// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_dao.dart';

// ignore_for_file: type=lint
mixin _$RoutineDaoMixin on DatabaseAccessor<AppDatabase> {
  $RoutineItemsTableTable get routineItemsTable =>
      attachedDatabase.routineItemsTable;
  RoutineDaoManager get managers => RoutineDaoManager(this);
}

class RoutineDaoManager {
  final _$RoutineDaoMixin _db;
  RoutineDaoManager(this._db);
  $$RoutineItemsTableTableTableManager get routineItemsTable =>
      $$RoutineItemsTableTableTableManager(
          _db.attachedDatabase, _db.routineItemsTable);
}
