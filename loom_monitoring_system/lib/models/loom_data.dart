import 'sensor_pack.dart';

/// Data model for loom system sensor and motor status
class LoomData {
  /// Hall sensors status (8 sensors: 0-7)
  final List<bool> hallSensors;

  /// Loom length in cm
  final double loomLength;

  /// Temperature in Celsius
  final double temperature;

  /// Motor status (10 motors: 0-9)
  final List<bool> motors;

  /// System connection status
  final bool isConnected;

  /// Total loom produced (in cm)
  final double totalLoomProduced;

  /// Last update timestamp
  final DateTime lastUpdated;

  /// Per-sensor loom length (in cm)
  final List<double> sensorLoomLengths;

  /// Servo motor status
  final ServoMotor? servoMotor;

  /// Sensor pack (8 sensors with active/inactive status)
  final SensorPack? sensorPack;

  /// Humidity percentage
  final double? humidity;

  LoomData({
    required this.hallSensors,
    required this.loomLength,
    required this.temperature,
    required this.motors,
    required this.isConnected,
    required this.totalLoomProduced,
    required this.lastUpdated,
    this.sensorLoomLengths = const [],
    this.servoMotor,
    this.sensorPack,
    this.humidity,
  });

  /// Factory constructor from JSON
  factory LoomData.fromJson(Map<String, dynamic> json) {
    // Parse servo motor data
    ServoMotor? servoMotor;
    if (json['servoMotor'] != null) {
      servoMotor = ServoMotor.fromJson(json['servoMotor'] as Map<String, dynamic>);
    }

    // Parse sensor pack data
    SensorPack? sensorPack;
    if (json['sensorPack'] != null) {
      sensorPack = SensorPack.fromJson(json['sensorPack'] as List);
    }

    return LoomData(
      hallSensors: List<bool>.from(json['hallSensors'] ?? []),
      loomLength: (json['loomLength'] ?? 0).toDouble(),
      temperature: (json['temperature'] ?? json['temp'] ?? 0).toDouble(),
      motors: List<bool>.from(json['motors'] ?? []),
      isConnected: json['isConnected'] ?? false,
      totalLoomProduced: (json['totalLoomProduced'] ?? 0).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toString()),
      sensorLoomLengths: List<double>.from((json['sensorLoomLengths'] as List?)?.map((x) => (x as num).toDouble()) ?? []),
      servoMotor: servoMotor,
      sensorPack: sensorPack,
      humidity: json['humidity'] != null ? (json['humidity'] as num).toDouble() : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'hallSensors': hallSensors,
      'loomLength': loomLength,
      'temperature': temperature,
      'motors': motors,
      'isConnected': isConnected,
      'totalLoomProduced': totalLoomProduced,
      'lastUpdated': lastUpdated.toIso8601String(),
      'sensorLoomLengths': sensorLoomLengths,
      'servoMotor': servoMotor?.toJson(),
      'sensorPack': sensorPack?.toJson(),
      'humidity': humidity,
    };
  }

  /// Create a copy with updated fields
  LoomData copyWith({
    List<bool>? hallSensors,
    double? loomLength,
    double? temperature,
    List<bool>? motors,
    bool? isConnected,
    double? totalLoomProduced,
    DateTime? lastUpdated,
    List<double>? sensorLoomLengths,
    ServoMotor? servoMotor,
    SensorPack? sensorPack,
    double? humidity,
  }) {
    return LoomData(
      hallSensors: hallSensors ?? this.hallSensors,
      loomLength: loomLength ?? this.loomLength,
      temperature: temperature ?? this.temperature,
      motors: motors ?? this.motors,
      isConnected: isConnected ?? this.isConnected,
      totalLoomProduced: totalLoomProduced ?? this.totalLoomProduced,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      sensorLoomLengths: sensorLoomLengths ?? this.sensorLoomLengths,
      servoMotor: servoMotor ?? this.servoMotor,
      sensorPack: sensorPack ?? this.sensorPack,
      humidity: humidity ?? this.humidity,
    );
  }

  /// Check if any hall sensor is not working (false)
  bool get hasFailedSensor => hallSensors.contains(false);

  /// Get failed sensor indices
  List<int> get failedSensorIndices {
    return List<int>.generate(
      hallSensors.length,
      (index) => index,
    ).where((index) => !hallSensors[index]).toList();
  }

  /// Check if temperature is above threshold (e.g., 50°C)
  bool get isTemperatureWarning => temperature > 50;

  /// Get number of active motors
  int get activeMotorCount => motors.where((m) => m).length;

  /// Check if servo motor is active
  bool get isServoMotorActive => servoMotor?.active ?? false;

  /// Check if servo motor is running
  bool get isServoMotorRunning => servoMotor?.running ?? false;

  /// Get active sensor count from sensor pack
  int get activeSensorPackCount => sensorPack?.activeSensorCount ?? 0;

  /// Get inactive sensor count from sensor pack
  int get inactiveSensorPackCount => sensorPack?.inactiveSensorCount ?? 0;
}
