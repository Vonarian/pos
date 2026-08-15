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
}
