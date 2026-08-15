import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/data/local/database.dart';
import 'package:pos_frontend/data/repositories/offline_metric_repository.dart';
import 'package:pos_frontend/data/repositories/offline_routine_repository.dart';
import 'package:pos_frontend/presentation/providers/metric_provider.dart';
import 'package:pos_frontend/presentation/providers/routine_provider.dart';
import 'package:pos_frontend/presentation/screens/dashboard_screen.dart';

void main() {
  testWidgets('Dashboard renders 4 quadrants and displays items', (
    WidgetTester tester,
  ) async {
    FlutterError.onError = (details) {
      debugPrint('TEST ERROR DETECTED: ${details.exception}');
      debugPrint('STACK: ${details.stack}');
    };

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final db = AppDatabase(NativeDatabase.memory());
    final now = DateTime.now();

    // Insert sample items into database
    await db.routineDao.upsertRoutine(
      RoutineItemsTableCompanion.insert(
        id: 'dash-1',
        title: 'Creatine 5g',
        category: 'MEDS',
        timeWindow: 'MORNING',
        scheduledDate:
            "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
        status: const Value('PENDING'),
        updatedAt: now,
        createdAt: now,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          offlineRoutineRepositoryProvider.overrideWithValue(
            OfflineRoutineRepository(db: db, apiClient: null),
          ),
          offlineMetricRepositoryProvider.overrideWithValue(
            OfflineMetricRepository(db: db, apiClient: null),
          ),
          dailyMetricSummaryProvider.overrideWith((ref) async => <String, double>{
                'STEPS': 5000,
                'CALORIES_BURNED': 1200,
              }),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify 4 quadrants are present
    expect(find.text('Morning Protocol'), findsOneWidget);
    expect(find.text('Mid-Day & Pre-Workout'), findsOneWidget);
    expect(find.text('Evening & Post-Workout'), findsOneWidget);
    expect(find.text('Night / Bedtime Stack'), findsOneWidget);

    // Verify item is shown
    expect(find.text('Creatine 5g'), findsOneWidget);
    expect(find.text('MEDS'), findsOneWidget);

    await db.close();
  });

  testWidgets('Completing a habit does NOT show a SnackBar', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final db = AppDatabase(NativeDatabase.memory());
    final now = DateTime.now();

    await db.routineDao.upsertRoutine(
      RoutineItemsTableCompanion.insert(
        id: 'dash-test-1',
        title: 'Morning Sunlight',
        category: 'HABIT',
        timeWindow: 'MORNING',
        scheduledDate:
            "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
        status: const Value('PENDING'),
        updatedAt: now,
        createdAt: now,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          offlineRoutineRepositoryProvider.overrideWithValue(
            OfflineRoutineRepository(db: db, apiClient: null),
          ),
          offlineMetricRepositoryProvider.overrideWithValue(
            OfflineMetricRepository(db: db, apiClient: null),
          ),
          dailyMetricSummaryProvider.overrideWith((ref) async => <String, double>{}),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Morning Sunlight'), findsOneWidget);

    // Tap checkmark to complete routine
    await tester.tap(find.byTooltip('Mark as Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Must NOT show any SnackBar
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Habit marked as completed'), findsNothing);

    // Verify status updated in DB
    final updated = await db.routineDao.getRoutineById('dash-test-1');
    expect(updated?.status, 'COMPLETED');

    await db.close();
  });

  testWidgets('Sync button animates in-place and shows checkmark without SnackBar', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          offlineRoutineRepositoryProvider.overrideWithValue(
            OfflineRoutineRepository(db: db, apiClient: null),
          ),
          offlineMetricRepositoryProvider.overrideWithValue(
            OfflineMetricRepository(db: db, apiClient: null),
          ),
          dailyMetricSummaryProvider.overrideWith((ref) async => <String, double>{}),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial sync button is present
    final syncButton = find.byTooltip('Sync now');
    expect(syncButton, findsOneWidget);

    // Tap sync button
    await tester.tap(syncButton);
    await tester.pump();

    // Verify checkmark appears after sync completes
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // Verify NO SnackBar is displayed
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Synchronized with Go backend'), findsNothing);

    // After 1.2s checkmark disappears and sync icon returns
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(find.byIcon(Icons.sync_rounded), findsOneWidget);

    await db.close();
  });
}

