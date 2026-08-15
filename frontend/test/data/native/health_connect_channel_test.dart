import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/domain/models/health_data_point.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.pos.app/health');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'checkAvailability':
            return true;
          case 'hasPermissions':
            return true;
          case 'getTodayAggregates':
            return {
              'steps': 6200,
              'calories': 1850.5,
            };
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
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
}
