import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/index.dart';

/// REST API Service for loom monitoring system
class ApiService {
  static const String _baseUrl = 'http://localhost:8080/api';
  static const Duration _timeout = Duration(seconds: 10);

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch current loom system status
  Future<ApiResponse<LoomData>> getLoomStatus() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/status'),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = LoomData.fromJson(jsonDecode(response.body));
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error(
          'Failed to fetch loom status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse.error('Error fetching loom status: $e');
    }
  }

  /// Control a motor
  Future<ApiResponse<bool>> controlMotor({
    required int motorId,
    required bool state,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/motor/control'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'motorId': motorId,
              'state': state,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Failed to control motor: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error controlling motor: $e');
    }
  }

  /// Release loom for specified length
  Future<ApiResponse<bool>> releaseLoom({required double lengthCm}) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/loom/release'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'lengthCm': lengthCm,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Failed to release loom: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error releasing loom: $e');
    }
  }

  /// Get system history
  Future<ApiResponse<Map<String, dynamic>>> getSystemHistory() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/history'),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error('Failed to fetch history: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error fetching history: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
