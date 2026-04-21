import 'dart:async';
import 'dart:math';
import '../models/index.dart';

/// Dummy data service for testing without backend
class DummyDataService {
  late Timer _updateTimer;
  late StreamController<LoomData> _streamController;
  
  final Random _random = Random();
  late LoomData _currentData;

  Stream<LoomData> get dataStream => _streamController.stream;

  void start() {
    _streamController = StreamController<LoomData>.broadcast();
    
    // Initialize with default data
    _currentData = _generateInitialData();
    _streamController.add(_currentData);
    
    // Update every 1 second
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _currentData = _generateUpdatedData();
      _streamController.add(_currentData);
    });
  }

  LoomData _generateInitialData() {
    return LoomData(
      hallSensors: List<bool>.generate(8, (_) => _random.nextBool()),
      loomLength: _random.nextDouble() * 100,
      temperature: 25 + _random.nextDouble() * 20,
      motors: List<bool>.generate(10, (_) => _random.nextBool()),
      isConnected: true,
      totalLoomProduced: 500 + _random.nextDouble() * 1000,
      lastUpdated: DateTime.now(),
    );
  }

  LoomData _generateUpdatedData() {
    // Slowly increment loom length
    double newLength = _currentData.loomLength + (_random.nextDouble() - 0.3);
    newLength = newLength.clamp(0, 200);
    
    // Slight temperature variation
    double newTemp = _currentData.temperature + (_random.nextDouble() - 0.5);
    newTemp = newTemp.clamp(20, 80);
    
    // Randomly toggle sensors (less frequently)
    List<bool> newSensors = List.from(_currentData.hallSensors);
    if (_random.nextDouble() < 0.05) {
      int randomIndex = _random.nextInt(8);
      newSensors[randomIndex] = !newSensors[randomIndex];
    }
    
    // Update total produced
    double newTotal = _currentData.totalLoomProduced + newLength * 0.1;
    
    return LoomData(
      hallSensors: newSensors,
      loomLength: newLength,
      temperature: newTemp,
      motors: _currentData.motors,
      isConnected: true,
      totalLoomProduced: newTotal,
      lastUpdated: DateTime.now(),
    );
  }

  void dispose() {
    _updateTimer.cancel();
    _streamController.close();
  }
}
