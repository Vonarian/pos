import 'package:dio/dio.dart';

import '../../domain/models/routine_item.dart';
import '../../domain/models/health_data_point.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({String baseUrl = 'http://localhost:8080'})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  Future<Map<String, dynamic>> getQuadrants(String date) async {
    final response = await _dio.get(
      '/api/v1/routines/quadrants',
      queryParameters: {'date': date},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> completeRoutine(String id, {DateTime? completedAt}) async {
    await _dio.post(
      '/api/v1/routines/complete',
      data: {
        'id': id,
        if (completedAt != null) 'completed_at': completedAt.toIso8601String(),
      },
    );
  }

  Future<void> skipRoutine(String id) async {
    await _dio.post('/api/v1/routines/skip', data: {'id': id});
  }

  Future<void> revertRoutine(String id) async {
    await _dio.post('/api/v1/routines/revert', data: {'id': id});
  }

  Future<void> deferRoutine(String id) async {
    await _dio.post('/api/v1/routines/defer', data: {'id': id});
  }

  Future<List<dynamic>> getMetricSeries(
    String metric, {
    String? from,
    String? to,
  }) async {
    final response = await _dio.get(
      '/api/v1/metrics/series',
      queryParameters: {'metric': metric, 'from': ?from, 'to': ?to},
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> pushSync({
    required List<RoutineItem> routines,
    required List<HealthDataPoint> metrics,
  }) async {
    final response = await _dio.post(
      '/api/v1/sync/push',
      data: {
        'routines': routines.map((e) => e.toJson()).toList(),
        'metrics': metrics.map((e) => e.toJson()).toList(),
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> pullSync({DateTime? since}) async {
    final params = <String, dynamic>{};
    if (since != null) {
      params['since'] = since.toIso8601String();
    }
    final response = await _dio.get(
      '/api/v1/sync/pull',
      queryParameters: params,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDailySummary(String date) async {
    final response = await _dio.get(
      '/api/v1/metrics/daily-summary',
      queryParameters: {'date': date},
    );
    return response.data as Map<String, dynamic>;
  }
}
