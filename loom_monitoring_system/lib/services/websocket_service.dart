import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/index.dart';

/// WebSocket Service for real-time loom data streaming
class WebSocketService {
  static const String _wsUrl = 'ws://localhost:3000/ws';
  
  WebSocketChannel? _channel;
  StreamController<LoomData>? _streamController;
  StreamController<String>? _statusController;
  
  bool _isConnected = false;
  Timer? _reconnectTimer;

  /// Get the stream of loom data updates
  Stream<LoomData>? get loomDataStream => _streamController?.stream;
  
  /// Get the connection status stream
  Stream<String>? get statusStream => _statusController?.stream;
  
  /// Check if connected
  bool get isConnected => _isConnected;

  /// Connect to WebSocket server
  Future<bool> connect() async {
    try {
      _streamController ??= StreamController<LoomData>.broadcast();
      _statusController ??= StreamController<String>.broadcast();
      
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      
      _isConnected = true;
      _statusController?.add('Connected');
      
      _channel?.stream.listen(
        (dynamic message) {
          try {
            final data = LoomData.fromJson(jsonDecode(message));
            _streamController?.add(data);
          } catch (e) {
            _statusController?.add('Error parsing data: $e');
          }
        },
        onError: (error) {
          _isConnected = false;
          _statusController?.add('Error: $error');
          _attemptReconnect();
        },
        onDone: () {
          _isConnected = false;
          _statusController?.add('Disconnected');
          _attemptReconnect();
        },
      );
      
      return true;
    } catch (e) {
      _isConnected = false;
      _statusController?.add('Connection failed: $e');
      _attemptReconnect();
      return false;
    }
  }

  /// Attempt to reconnect after disconnection
  void _attemptReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect();
    });
  }

  /// Send a message to the server
  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      _channel?.sink.add(jsonEncode(message));
    }
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _channel?.sink.close();
    _isConnected = false;
    _statusController?.add('Disconnected');
  }

  /// Dispose resources
  void dispose() {
    _reconnectTimer?.cancel();
    disconnect();
    _streamController?.close();
    _statusController?.close();
  }
}
