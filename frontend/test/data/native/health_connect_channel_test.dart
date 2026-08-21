import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/data/native/health_connect_channel.dart';
import 'package:pos_frontend/domain/models/health_data_point.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.pos.app/health');

  setUp(() {
    HealthConnectChannel.overrideIsAndroid = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'checkAvailability':
              return true;
            case 'hasPermissions':
              return true;
            case 'getTodayAggregates':
            case 'getTodayMetrics':
              return {
                'steps': 6200,
                'calories': 2100.0,
                'nutritionCalories': 2100.0,
                'burnedCalories': 450.0,
                'sleepMinutes': 480.0,
                'weightKg': 75.0,
                'date': '2026-08-15',
              };
            case 'getHealthHistory':
              return [
                {
                  'date': '2026-08-15',
                  'steps': 6200,
                  'calories': 2100.0,
                  'nutritionCalories': 2100.0,
                  'burnedCalories': 450.0,
                  'sleepMinutes': 480.0,
                  'weightKg': 75.0,
                },
              ];
            default:
              return null;
          }
        });
  });

  tearDown(() {
    HealthConnectChannel.overrideIsAndroid = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('HealthDataPoint domain parsing from health connect channel', () {
    final now = DateTime.now();
    final pt = HealthDataPoint(
      id: 'hc-step-test',
      source: 'health_connect',
      metric: MetricType.steps,
      value: 6200,
      unit: 'count',
      startTime: now.subtract(const Duration(hours: 1)),
      endTime: now,
      syncedAt: now,
    );

    expect(pt.metric, MetricType.steps);
    expect(pt.value, 6200);
    expect(pt.unit, 'count');
  });

  test('MetricType supports caloriesConsumed', () {
    expect(
      MetricType.fromString('CALORIES_CONSUMED'),
      MetricType.caloriesConsumed,
    );
    expect(MetricType.fromString('NUTRITION'), MetricType.caloriesConsumed);
  });

  test(
    'HealthConnectChannel reads nutrition and calories aggregates',
    () async {
      final metrics = await HealthConnectChannel.getTodayMetrics();
      expect(metrics['STEPS'], 6200);
      expect(metrics['CALORIES_CONSUMED'], 2100.0);
      expect(metrics['CALORIES_BURNED'], 450.0);
      expect(metrics['SLEEP_DURATION'], 480.0);
      expect(metrics['WEIGHT'], 75.0);
    },
  );
}
