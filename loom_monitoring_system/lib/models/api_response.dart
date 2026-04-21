/// Generic API response wrapper
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool success;

  ApiResponse({
    this.data,
    this.error,
    this.success = false,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse(data: data, success: true);
  }

  factory ApiResponse.error(String error) {
    return ApiResponse(error: error, success: false);
  }
}

/// Motor control command
class MotorCommand {
  final int motorId;
  final bool state;

  MotorCommand({required this.motorId, required this.state});

  Map<String, dynamic> toJson() {
    return {
      'motorId': motorId,
      'state': state,
    };
  }
}

/// Loom release command
class LoomReleaseCommand {
  final double lengthCm;

  LoomReleaseCommand({required this.lengthCm});

  Map<String, dynamic> toJson() {
    return {
      'lengthCm': lengthCm,
    };
  }
}
