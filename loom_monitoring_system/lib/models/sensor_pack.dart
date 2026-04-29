/// Model for individual sensor in the sensor pack
class SensorPackItem {
  /// Sensor ID (0-7)
  final int id;

  /// Sensor status (active/inactive)
  final String status;

  /// Whether sensor is active
  final bool active;

  SensorPackItem({
    required this.id,
    required this.status,
    required this.active,
  });

  /// Factory constructor from JSON
  factory SensorPackItem.fromJson(Map<String, dynamic> json) {
    return SensorPackItem(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'inactive',
      active: json['active'] ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'active': active,
    };
  }
}

/// Model for servo motor status
class ServoMotor {
  /// Whether servo motor is active
  final bool active;

  /// Whether motor is currently running
  final bool running;

  ServoMotor({
    required this.active,
    required this.running,
  });

  /// Factory constructor from JSON
  factory ServoMotor.fromJson(Map<String, dynamic> json) {
    return ServoMotor(
      active: json['active'] ?? false,
      running: json['running'] ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'active': active,
      'running': running,
    };
  }

  /// Get status string
  String get statusString => active
      ? (running ? 'RUNNING' : 'ACTIVE')
      : 'INACTIVE';

  /// Get status color
  String get statusColor => active
      ? (running ? '#FFC107' : '#4CAF50')
      : '#F44336';
}

/// Model for sensor pack (8 sensors)
class SensorPack {
  /// List of 8 sensors
  final List<SensorPackItem> sensors;

  SensorPack({required this.sensors});

  /// Factory constructor from JSON
  factory SensorPack.fromJson(List<dynamic> json) {
    return SensorPack(
      sensors: json.map((e) => SensorPackItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// Convert to JSON
  List<Map<String, dynamic>> toJson() {
    return sensors.map((s) => s.toJson()).toList();
  }

  /// Get number of active sensors
  int get activeSensorCount => sensors.where((s) => s.active).length;

  /// Get number of inactive sensors
  int get inactiveSensorCount => sensors.where((s) => !s.active).length;

  /// Get inactive sensor indices
  List<int> get inactiveSensorIndices =>
      sensors.where((s) => !s.active).map((s) => s.id).toList();
}
