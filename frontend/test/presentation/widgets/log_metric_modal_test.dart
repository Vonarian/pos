import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/data/local/database.dart';
import 'package:pos_frontend/data/repositories/offline_metric_repository.dart';
import 'package:pos_frontend/domain/models/health_data_point.dart';
import 'package:pos_frontend/presentation/providers/metric_provider.dart';
import 'package:pos_frontend/presentation/providers/routine_provider.dart';
import 'package:pos_frontend/presentation/widgets/log_metric_modal.dart';

void main() {
  testWidgets(
    'LogMetricModal saves entry with checkmark feedback and no SnackBar',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final db = AppDatabase(NativeDatabase.memory());
      final metricRepo = OfflineMetricRepository(db: db, apiClient: null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            offlineMetricRepositoryProvider.overrideWithValue(metricRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LogMetricModal(initialMetric: MetricType.weight),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Log Health Metric'), findsOneWidget);
      expect(find.text('Save Entry'), findsOneWidget);

      // Enter weight value
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, '75.5');
      await tester.pump();

      // Tap Save Entry
      await tester.tap(find.text('Save Entry'));
      await tester.pump();

      // In-place checkmark feedback should be visible during the 250ms window
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // No SnackBar should be displayed
      expect(find.byType(SnackBar), findsNothing);

      // Wait for the feedback duration and modal pop
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify data in repository/db
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day);
      final to = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final points = await metricRepo.getMetricSeries(
        MetricType.weight,
        from,
        to,
      );
      expect(points.length, 1);
      expect(points.first.value, 75.5);

      await db.close();
    },
  );

  testWidgets('LogMetricModal does not save when input is invalid', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final db = AppDatabase(NativeDatabase.memory());
    final metricRepo = OfflineMetricRepository(db: db, apiClient: null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          offlineMetricRepositoryProvider.overrideWithValue(metricRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: LogMetricModal(initialMetric: MetricType.waterIntake),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap save with empty value
    await tester.tap(find.text('Save Entry'));
    await tester.pump();

    // Checkmark should not appear and no SnackBar
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(find.byType(SnackBar), findsNothing);

    final now = DateTime.now();
    final points = await metricRepo.getMetricSeries(
      MetricType.waterIntake,
      DateTime(now.year, now.month, now.day),
      DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
    expect(points.isEmpty, isTrue);

    await db.close();
  });
}
