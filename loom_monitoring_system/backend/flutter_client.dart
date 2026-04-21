/**
 * LOOM BACKEND - FLUTTER DART CLIENT
 * 
 * Use this in your Flutter app to communicate with the backend
 * Copy this code to lib/services/backend_service.dart
 */

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class BackendService {
  static const String baseUrl = 'http://localhost:3000';
  static const String wsUrl = 'ws://localhost:3000';
  
  static final BackendService _instance = BackendService._internal();
  
  WebSocketChannel? _webSocket;
  StreamSubscription? _wsSubscription;
  
  factory BackendService() {
    return _instance;
  }
  
  BackendService._internal();
  
  // ==================== HEALTH CHECK ====================
  
  /// Check if backend is online
  Future<Map<String, dynamic>?> getHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Health check error: $e');
    }
    return null;
  }
  
  // ==================== REST API ENDPOINTS ====================
  
  /// Get current system status
  Future<Map<String, dynamic>?> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/status'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Get status error: $e');
    }
    return null;
  }
  
  /// Control a motor
  /// motorId: 0-9
  /// state: true (ON) or false (OFF)
  Future<bool> controlMotor(int motorId, bool state) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/motor/control'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'motorId': motorId,
          'state': state,
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      print('Motor control error: $e');
    }
    return false;
  }
  
  /// Release loom fabric
  /// lengthCm: length in centimeters (0.1 - 50)
  Future<bool> releaseLoom(double lengthCm) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/loom/release'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lengthCm': lengthCm,
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      print('Release loom error: $e');
    }
    return false;
  }
  
  /// Get system history
  Future<Map<String, dynamic>?> getHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/history'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Get history error: $e');
    }
    return null;
  }
  
  /// Get system logs
  Future<List<dynamic>?> getLogs({int limit = 100, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/logs?limit=$limit&offset=$offset'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['logs'];
      }
    } catch (e) {
      print('Get logs error: $e');
    }
    return null;
  }
  
  /// Get events
  Future<List<dynamic>?> getEvents({
    int limit = 100,
    int offset = 0,
    String? type,
  }) async {
    try {
      String url = '$baseUrl/api/events?limit=$limit&offset=$offset';
      if (type != null) url += '&type=$type';
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['events'];
      }
    } catch (e) {
      print('Get events error: $e');
    }
    return null;
  }
  
  /// Get statistics
  Future<Map<String, dynamic>?> getStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/statistics'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Get statistics error: $e');
    }
    return null;
  }
  
  // ==================== WEBSOCKET ====================
  
  /// Connect to WebSocket for real-time updates
  void connectWebSocket(
    Function(Map<String, dynamic>) onMessage,
    Function()? onConnected,
    Function()? onError,
    Function()? onClosed,
  ) {
    try {
      _webSocket = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Send subscription request
      _webSocket!.sink.add(jsonEncode({
        'type': 'subscribe_status',
      }));
      
      // Listen for messages
      _wsSubscription = _webSocket!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            onMessage(data);
          } catch (e) {
            print('WebSocket parse error: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          if (onError != null) onError();
        },
        onDone: () {
          print('WebSocket closed');
          if (onClosed != null) onClosed();
        },
      );
      
      if (onConnected != null) onConnected();
    } catch (e) {
      print('WebSocket connection error: $e');
      if (onError != null) onError();
    }
  }
  
  /// Disconnect WebSocket
  void disconnectWebSocket() {
    _wsSubscription?.cancel();
    _webSocket?.sink.close();
  }
  
  /// Send WebSocket message
  void sendWebSocketMessage(Map<String, dynamic> message) {
    try {
      _webSocket?.sink.add(jsonEncode(message));
    } catch (e) {
      print('WebSocket send error: $e');
    }
  }
  
  /// Check if WebSocket is connected
  bool get isWebSocketConnected => _webSocket != null;
}

// ==================== USAGE EXAMPLE ====================

/*
// In your Flutter widget:

final backend = BackendService();

// Check health
final health = await backend.getHealth();

// Get status
final status = await backend.getStatus();

// Control motor
await backend.controlMotor(0, true);

// Release loom
await backend.releaseLoom(4.0);

// Connect WebSocket
backend.connectWebSocket(
  (data) {
    print('Message: ${data['type']}');
    
    if (data['type'] == 'status_update') {
      // Update UI with new status
    } else if (data['type'] == 'motor_control') {
      // Motor was controlled
    } else if (data['type'] == 'loom_release') {
      // Loom was released
    }
  },
  onConnected: () {
    print('Connected');
  },
  onError: () {
    print('WebSocket error');
  },
  onClosed: () {
    print('Disconnected');
  },
);

// Later, disconnect
backend.disconnectWebSocket();
*/
