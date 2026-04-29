import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/index.dart';

/// REST API Service for loom monitoring system
class ApiService {
  static const String _baseUrl = 'http://localhost:3000/api';
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

  /// Fetch latest sensor data from backend (ESP32)
  Future<ApiResponse<LoomData>> getLatestSensorData() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/esp32/latest-sensor-data'),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'] as Map<String, dynamic>;
          
          // Parse sensor pack
          SensorPack? sensorPack;
          try {
            final sensorPackData = data['sensorPack'] as Map<String, dynamic>?;
            if (sensorPackData != null && sensorPackData['sensors'] != null) {
              final sensors = (sensorPackData['sensors'] as List).map((s) {
                return SensorPackItem.fromJson(s as Map<String, dynamic>);
              }).toList();
              sensorPack = SensorPack(sensors: sensors);
            }
          } catch (e) {
            print('Error parsing sensor pack: $e');
          }

          // Parse servo motor
          ServoMotor? servoMotor;
          try {
            final servoData = data['servoMotor'] as Map<String, dynamic>?;
            if (servoData != null) {
              servoMotor = ServoMotor.fromJson(servoData);
            }
          } catch (e) {
            print('Error parsing servo motor: $e');
          }

          // Parse hall sensors (legacy)
          final hallSensors = (data['hallSensors'] as List?)
                  ?.map((s) => s == true || s == 1)
                  .toList() ??
              List<bool>.filled(8, false);

          final loomData = LoomData(
            hallSensors: hallSensors,
            loomLength: (data['loomLength'] as num?)?.toDouble() ?? 0.0,
            temperature: (data['temp'] as num?)?.toDouble() ?? 0.0,
            motors: List<bool>.generate(10, (i) => false),
            isConnected: true,
            totalLoomProduced: (data['totalLoomProduced'] as num?)?.toDouble() ?? 0.0,
            lastUpdated: data['timestamp'] != null 
              ? DateTime.parse(data['timestamp'].toString())
              : DateTime.now(),
            servoMotor: servoMotor,
            sensorPack: sensorPack,
            humidity: (data['humidity'] as num?)?.toDouble(),
          );

          return ApiResponse.success(loomData);
        } else {
          return ApiResponse.error('No sensor data available from backend');
        }
      } else {
        return ApiResponse.error('Failed to fetch sensor data: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error fetching sensor data: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
