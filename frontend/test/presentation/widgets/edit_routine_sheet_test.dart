import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/domain/models/routine_item.dart';
import 'package:pos_frontend/presentation/widgets/edit_routine_sheet.dart';

void main() {
  testWidgets('EditRoutineSheet pre-fills fields and saves updated routine', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final item = RoutineItem(
      id: 'test-item-1',
      templateId: 'tpl-1',
      title: 'Original Title',
      category: 'Meds/Supps',
      timeWindow: TimeWindow.morning,
      scheduledDate: '2026-08-15',
      status: ItemStatus.pending,
      metadata: {
        'dosage': '500mg',
        'reminder': {
          'enabled': true,
          'time': '08:00',
          'days_of_week': [1, 2, 3, 4, 5, 6, 7],
        },
      },
      updatedAt: now,
      createdAt: now,
    );

    RoutineItem? savedItem;
    bool? savedApplyToFuture;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditRoutineSheet(
            item: item,
            onSave: (updated, applyToFuture) {
              savedItem = updated;
              savedApplyToFuture = applyToFuture;
            },
          ),
        ),
      ),
    );

    // Verify initial values
    expect(find.text('Edit Habit / Medication'), findsOneWidget);
    expect(find.text('Original Title'), findsOneWidget);
    expect(find.text('500mg'), findsOneWidget);

    // Modify Title
    await tester.enterText(find.byType(TextField).first, 'Updated Title');

    // Scroll to Save Changes button and tap
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(savedItem, isNotNull);
    expect(savedItem!.title, 'Updated Title');
    expect(savedApplyToFuture, isTrue);
  });
}
