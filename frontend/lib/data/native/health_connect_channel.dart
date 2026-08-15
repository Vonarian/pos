import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../domain/models/health_data_point.dart';

class HealthConnectChannel {
  static const MethodChannel _channel = MethodChannel('com.pos.app/health');

  @visibleForTesting
  static bool overrideIsAndroid = false;

  static bool get _isAndroid => Platform.isAndroid || overrideIsAndroid;

  static Future<bool> isAvailable() async {
    if (!_isAndroid) return false;
    try {
      final available = await _channel.invokeMethod<bool>('checkAvailability');
      return available ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasPermissions() async {
    if (!_isAndroid) return false;
    try {
      final granted = await _channel.invokeMethod<bool>('hasPermissions');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPermissions() async {
    if (!_isAndroid) return false;
    try {
      final granted = await _channel.invokeMethod<bool>('requestPermissions');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, double>> getTodayMetrics() async {
    if (!_isAndroid) return {};
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getTodayMetrics');
      if (res == null) return {};
      final map = <String, double>{};
      map['STEPS'] = (res['steps'] as num?)?.toDouble() ?? 0.0;
      map['CALORIES_BURNED'] = (res['calories'] as num?)?.toDouble() ?? 0.0;
      map['SLEEP_DURATION'] = (res['sleepMinutes'] as num?)?.toDouble() ?? 0.0;
      map['WEIGHT'] = (res['weightKg'] as num?)?.toDouble() ?? 0.0;
      return map;
    } catch (_) {
      return {};
    }
  }

  static Future<List<HealthDataPoint>> getTodayAggregates() async {
    return getHealthHistory(days: 1);
  }

  static Future<List<HealthDataPoint>> getHealthHistory({int days = 30}) async {
    if (!_isAndroid) return [];
    try {
      final list = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'getHealthHistory',
        {'days': days},
      );
      if (list == null) return [];

      final now = DateTime.now();
      final points = <HealthDataPoint>[];

      for (final raw in list) {
        final item = Map<String, dynamic>.from(raw);
        final dateStr = item['date'] as String? ?? DateFormat('yyyy-MM-dd').format(now);
        final parsedDate = DateTime.tryParse(dateStr) ?? now;
        final startOfDay = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
        final endOfDay = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, 23, 59, 59);

        final steps = (item['steps'] as num?)?.toDouble() ?? 0.0;
        if (steps > 0) {
          points.add(HealthDataPoint(
            id: 'hc-steps-$dateStr',
            source: 'health_connect',
            metric: MetricType.steps,
            value: steps,
            unit: 'count',
            startTime: startOfDay,
            endTime: endOfDay,
            syncedAt: now,
          ));
        }

        final calories = (item['calories'] as num?)?.toDouble() ?? 0.0;
        if (calories > 0) {
          points.add(HealthDataPoint(
            id: 'hc-cal-$dateStr',
            source: 'health_connect',
            metric: MetricType.caloriesBurned,
            value: calories,
            unit: 'kcal',
            startTime: startOfDay,
            endTime: endOfDay,
            syncedAt: now,
          ));
        }

        final sleepMin = (item['sleepMinutes'] as num?)?.toDouble() ?? 0.0;
        if (sleepMin > 0) {
          points.add(HealthDataPoint(
            id: 'hc-sleep-$dateStr',
            source: 'health_connect',
            metric: MetricType.sleepDuration,
            value: sleepMin,
            unit: 'minutes',
            startTime: startOfDay,
            endTime: endOfDay,
            syncedAt: now,
          ));
        }

        final weight = (item['weightKg'] as num?)?.toDouble() ?? 0.0;
        if (weight > 0) {
          points.add(HealthDataPoint(
            id: 'hc-weight-$dateStr',
            source: 'health_connect',
            metric: MetricType.weight,
            value: weight,
            unit: 'kg',
            startTime: startOfDay,
            endTime: endOfDay,
            syncedAt: now,
          ));
        }
      }

      return points;
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getRawHealthData({int days = 30}) async {
    if (!_isAndroid) return {};
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'getRawHealthData',
        {'days': days},
      );
      return res ?? {};
    } catch (_) {
      return {};
    }
  }
}
