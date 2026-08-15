import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/data/local/database.dart';
import 'package:pos_frontend/domain/models/routine_item.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('RoutineTemplateDao CRUD and active templates query', () async {
    final now = DateTime.now();

    // 1. Insert active template
    await db.routineTemplateDao.upsertTemplate(
      RoutineTemplatesTableCompanion.insert(
        id: 'tpl_1',
        title: 'Morning Creatine',
        category: 'Meds/Supps',
        timeWindow: TimeWindow.morning.value,
        daysOfWeekJson: const Value('[1,2,3,4,5,6,7]'),
        metadataJson: Value(
          jsonEncode({
            'dosage': '5g',
            'reminder': {'enabled': true, 'time': '08:00', 'days': [1, 2, 3, 4, 5, 6, 7]},
          }),
        ),
        isActive: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );

    // 2. Insert inactive template
    await db.routineTemplateDao.upsertTemplate(
      RoutineTemplatesTableCompanion.insert(
        id: 'tpl_2',
        title: 'Old Habit',
        category: 'Training',
        timeWindow: TimeWindow.afternoon.value,
        daysOfWeekJson: const Value('[1,2,3]'),
        metadataJson: const Value('{}'),
        isActive: const Value(false),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final activeTemplates = await db.routineTemplateDao.getActiveTemplates();
    expect(activeTemplates.length, equals(1));
    expect(activeTemplates.first.id, equals('tpl_1'));
    expect(activeTemplates.first.title, equals('Morning Creatine'));

    // 3. Deactivate template
    await db.routineTemplateDao.deactivateTemplate('tpl_1');
    final afterDeactivate = await db.routineTemplateDao.getActiveTemplates();
    expect(afterDeactivate.isEmpty, isTrue);
  });
}
