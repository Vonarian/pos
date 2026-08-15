import 'dart:io';
import 'package:flutter/services.dart';
import '../../domain/models/health_data_point.dart';

class HealthConnectChannel {
  static const MethodChannel _channel = MethodChannel('com.pos.app/health');

  static Future<bool> isAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      final available = await _channel.invokeMethod<bool>('checkAvailability');
      return available ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasPermissions() async {
    if (!Platform.isAndroid) return false;
    try {
      final granted = await _channel.invokeMethod<bool>('hasPermissions');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<HealthDataPoint>> getTodayAggregates() async {
    if (!Platform.isAndroid) return [];
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getTodayAggregates');
      if (result == null) return [];

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final list = <HealthDataPoint>[];

      if (result.containsKey('steps')) {
        list.add(HealthDataPoint(
          id: 'hc-steps-${now.millisecondsSinceEpoch}',
          source: 'health_connect',
          metric: MetricType.steps,
          value: (result['steps'] as num).toDouble(),
          unit: 'count',
          startTime: startOfDay,
          endTime: now,
          syncedAt: now,
        ));
      }

      if (result.containsKey('calories')) {
        list.add(HealthDataPoint(
          id: 'hc-cal-${now.millisecondsSinceEpoch}',
          source: 'health_connect',
          metric: MetricType.caloriesBurned,
          value: (result['calories'] as num).toDouble(),
          unit: 'kcal',
          startTime: startOfDay,
          endTime: now,
          syncedAt: now,
        ));
      }

      return list;
    } catch (_) {
      return [];
    }
  }
}
