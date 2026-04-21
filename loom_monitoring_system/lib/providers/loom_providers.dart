import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/index.dart';

/// Global providers for loom monitoring system

// API Service provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// WebSocket Service provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});

// Dummy Data Service provider
final dummyDataServiceProvider = Provider<DummyDataService>((ref) {
  return DummyDataService();
});

// Current loom data state notifier
class LoomDataNotifier extends StateNotifier<LoomData?> {
  final DummyDataService dummyDataService;

  LoomDataNotifier(this.dummyDataService) : super(null) {
    _initializeData();
  }

  void _initializeData() {
    dummyDataService.start();
    dummyDataService.dataStream.listen((data) {
      state = data;
    });
  }

  void dispose() {
    dummyDataService.dispose();
  }
}

// Loom data provider
final loomDataProvider = StateNotifierProvider<LoomDataNotifier, LoomData?>((ref) {
  final dummyService = ref.watch(dummyDataServiceProvider);
  return LoomDataNotifier(dummyService);
});

// Connection status provider
final connectionStatusProvider = StateProvider<bool>((ref) {
  final data = ref.watch(loomDataProvider);
  return data?.isConnected ?? false;
});

// Temperature warning provider
final temperatureWarningProvider = Provider<bool>((ref) {
  final data = ref.watch(loomDataProvider);
  return data?.isTemperatureWarning ?? false;
});

// Failed sensors provider
final failedSensorsProvider = Provider<List<int>>((ref) {
  final data = ref.watch(loomDataProvider);
  return data?.failedSensorIndices ?? [];
});

// Active motors count provider
final activeMotorsCountProvider = Provider<int>((ref) {
  final data = ref.watch(loomDataProvider);
  return data?.activeMotorCount ?? 0;
});
