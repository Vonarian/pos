import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/data/local/database.dart';
import 'package:pos_frontend/data/repositories/offline_metric_repository.dart';
import 'package:pos_frontend/domain/models/health_data_point.dart';
import 'package:pos_frontend/presentation/providers/metric_provider.dart';
import 'package:pos_frontend/presentation/providers/routine_provider.dart';
import 'package:pos_frontend/presentation/screens/analytics_screen.dart';

void main() {
  testWidgets('AnalyticsScreen renders tabs, time horizon, chart card, and FAB', (
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
          metricSeriesProvider.overrideWith((ref) async => <HealthDataPoint>[]),
        ],
        child: const MaterialApp(home: AnalyticsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Health Analytics'), findsOneWidget);
    expect(find.text('Time Horizon'), findsOneWidget);
    expect(find.text('7D'), findsOneWidget);
    expect(find.text('14D'), findsOneWidget);
    expect(find.text('30D'), findsOneWidget);

    expect(find.text('Steps'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Burned'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);

    expect(find.text('Manual Entry'), findsOneWidget);
    expect(find.text('Log Metric'), findsOneWidget);

    await db.close();
  });

  testWidgets('AnalyticsScreen opening modal and logging metric shows checkmark and no SnackBar', (
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
          metricSeriesProvider.overrideWith((ref) async => <HealthDataPoint>[]),
        ],
        child: const MaterialApp(home: AnalyticsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Tap FAB to open modal
    await tester.tap(find.text('Log Metric'));
    await tester.pumpAndSettle();

    expect(find.text('Log Health Metric'), findsOneWidget);

    // Enter value in textfield
    final textField = find.byType(TextField);
    await tester.enterText(textField, '8000');
    await tester.pump();

    // Tap Save Entry
    await tester.tap(find.text('Save Entry'));
    await tester.pump();

    // Checkmark feedback appears on button
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // No SnackBar must be present
    expect(find.byType(SnackBar), findsNothing);

    // Wait for pop
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Modal is dismissed
    expect(find.text('Log Health Metric'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);

    await db.close();
  });
}
