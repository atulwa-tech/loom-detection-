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
    // Generate sensor pack data (8 sensors)
    final sensorPackItems = List<SensorPackItem>.generate(8, (i) {
      final isActive = _random.nextBool();
      return SensorPackItem(
        id: i,
        status: isActive ? 'active' : 'inactive',
        active: isActive,
      );
    });
    final sensorPack = SensorPack(sensors: sensorPackItems);

    // Generate servo motor data
    final servoMotor = ServoMotor(
      active: true,
      running: _random.nextBool(),
    );

    return LoomData(
      hallSensors: List<bool>.generate(8, (_) => _random.nextBool()),
      loomLength: _random.nextDouble() * 100,
      temperature: 25 + _random.nextDouble() * 20,
      motors: List<bool>.generate(10, (_) => _random.nextBool()),
      isConnected: true,
      totalLoomProduced: 500 + _random.nextDouble() * 1000,
      lastUpdated: DateTime.now(),
      sensorPack: sensorPack,
      servoMotor: servoMotor,
      humidity: 40 + _random.nextDouble() * 30,
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
    
    // Update sensor pack (occasionally toggle sensor status)
    SensorPack? newSensorPack;
    if (_currentData.sensorPack != null) {
      List<SensorPackItem> updatedSensors = _currentData.sensorPack!.sensors.map((s) {
        bool newActive = s.active;
        if (_random.nextDouble() < 0.08) {
          newActive = !newActive;
        }
        return SensorPackItem(
          id: s.id,
          status: newActive ? 'active' : 'inactive',
          active: newActive,
        );
      }).toList();
      newSensorPack = SensorPack(sensors: updatedSensors);
    }
    
    // Update servo motor status (occasionally toggle)
    ServoMotor? newServoMotor;
    if (_currentData.servoMotor != null) {
      bool newRunning = _currentData.servoMotor!.running;
      if (_random.nextDouble() < 0.1) {
        newRunning = !newRunning;
      }
      newServoMotor = ServoMotor(
        active: _currentData.servoMotor!.active,
        running: newRunning,
      );
    }
    
    // Update total produced
    double newTotal = _currentData.totalLoomProduced + newLength * 0.1;
    
    // Update humidity
    double newHumidity = (_currentData.humidity ?? 50) + (_random.nextDouble() - 0.5);
    newHumidity = newHumidity.clamp(20, 80);
    
    return LoomData(
      hallSensors: newSensors,
      loomLength: newLength,
      temperature: newTemp,
      motors: _currentData.motors,
      isConnected: true,
      totalLoomProduced: newTotal,
      lastUpdated: DateTime.now(),
      sensorPack: newSensorPack,
      servoMotor: newServoMotor,
      humidity: newHumidity,
    );
  }

  void dispose() {
    _updateTimer.cancel();
    _streamController.close();
  }
}
