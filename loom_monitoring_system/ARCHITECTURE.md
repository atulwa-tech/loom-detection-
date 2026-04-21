# Architecture & Design Documentation

This document explains the architecture, design patterns, and how different components interact in the Loom Monitoring System.

## Architecture Overview

The app follows a **Clean Architecture** pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────────┐
│                     UI Layer (Flutter Widgets)                   │
│        DashboardScreen, HallSensorCard, MotorCard, etc.         │
└─────────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────────┐
│              State Management Layer (Riverpod)                   │
│        loomDataProvider, temperatureWarningProvider, etc.       │
└─────────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────────┐
│           Business Logic Layer (Services)                        │
│    ApiService, WebSocketService, DummyDataService              │
└─────────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────────┐
│            Data Layer (Models & HTTP/WebSocket)                 │
│        LoomData, ApiResponse, HTTP Client, WebSocket            │
└─────────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────────┐
│                  Backend API (ESP32/REST)                        │
│              /api/status, /api/motor/control, etc.              │
└─────────────────────────────────────────────────────────────────┘
```

## Layer Descriptions

### 1. UI Layer (`lib/screens/`, `lib/widgets/`)

**Responsibility**: Present data to users and capture interactions

**Components**:
- `DashboardScreen` - Main dashboard displaying all information
- `HallSensorCard` - Individual sensor status widget
- `MotorCard` - Motor control widget
- `LoomLengthCard` - Length display
- `TemperatureCard` - Temperature display with warnings
- `StatusIndicator` - Connection status
- `LoomControlButton` - Release control buttons

**Key Features**:
- Uses `ConsumerWidget` for reactive updates
- Automatic rebuilds only when relevant data changes
- Responsive grid layouts
- Material 3 design language

**Example**:
```dart
// DashboardScreen watches Riverpod providers
final loomData = ref.watch(loomDataProvider);
final isConnected = ref.watch(connectionStatusProvider);
// UI automatically updates when these change
```

### 2. State Management Layer (`lib/providers/`)

**Responsibility**: Manage application state and notify UI of changes

**Technology**: Flutter Riverpod

**Providers**:
- `loomDataProvider` - Main system status (StreamNotifier)
- `connectionStatusProvider` - Connection state
- `temperatureWarningProvider` - Temperature alert state
- `failedSensorsProvider` - Failed sensor indices
- `activeMotorsCountProvider` - Active motor count

**Key Advantages**:
- ✅ Automatic dependency management
- ✅ Efficient rebuilds (only affected widgets update)
- ✅ Easy testing (can provide mock data)
- ✅ Thread-safe state management
- ✅ No BuildContext required

**Example**:
```dart
final loomDataProvider = StateNotifierProvider<LoomDataNotifier, LoomData?>((ref) {
  final dummyService = ref.watch(dummyDataServiceProvider);
  return LoomDataNotifier(dummyService);
});
```

### 3. Business Logic Layer (`lib/services/`)

**Responsibility**: Handle API calls and data transformation

**Services**:

#### ApiService
- REST API communication
- HTTP client with timeout handling
- Methods: `getLoomStatus()`, `controlMotor()`, `releaseLoom()`, `getSystemHistory()`

```dart
Future<ApiResponse<LoomData>> getLoomStatus() async {
  try {
    final response = await _client.get(Uri.parse('$_baseUrl/status')).timeout(_timeout);
    if (response.statusCode == 200) {
      return ApiResponse.success(LoomData.fromJson(jsonDecode(response.body)));
    }
    return ApiResponse.error('Failed');
  } catch (e) {
    return ApiResponse.error('Error: $e');
  }
}
```

#### WebSocketService
- Real-time data streaming
- Auto-reconnection on disconnect
- Stream-based architecture

```dart
Stream<LoomData>? get loomDataStream => _streamController?.stream;

Future<bool> connect() async {
  _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
  _channel?.stream.listen((message) {
    _streamController?.add(LoomData.fromJson(jsonDecode(message)));
  });
  return true;
}
```

#### DummyDataService
- Generates realistic test data
- Perfect for UI testing without backend
- Simulates sensor changes and temperature variations

```dart
void start() {
  _streamController = StreamController<LoomData>.broadcast();
  _currentData = _generateInitialData();
  _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
    _currentData = _generateUpdatedData();
    _streamController.add(_currentData);
  });
}
```

### 4. Data Layer (`lib/models/`)

**Responsibility**: Define data structures and serialization

**Models**:

#### LoomData
Main data model containing all system information

```dart
class LoomData {
  final List<bool> hallSensors;    // 8 sensors
  final double loomLength;          // in cm
  final double temperature;         // in °C
  final List<bool> motors;          // 10 motors
  final bool isConnected;
  final double totalLoomProduced;   // in cm
  final DateTime lastUpdated;
  
  // Computed properties
  bool get isTemperatureWarning => temperature > 50;
  bool get hasFailedSensor => hallSensors.contains(false);
  List<int> get failedSensorIndices => /* ... */;
}
```

#### ApiResponse
Generic response wrapper for type safety

```dart
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool success;
  
  factory ApiResponse.success(T data) => ApiResponse(data: data, success: true);
  factory ApiResponse.error(String error) => ApiResponse(error: error, success: false);
}
```

#### Motor/Loom Commands
Request models for API calls

```dart
class MotorCommand {
  final int motorId;
  final bool state;
  Map<String, dynamic> toJson() => {'motorId': motorId, 'state': state};
}

class LoomReleaseCommand {
  final double lengthCm;
  Map<String, dynamic> toJson() => {'lengthCm': lengthCm};
}
```

### 5. Backend Layer (External)

**Responsibility**: Sensor reading and motor control

**Expected Endpoints**:
- `GET /api/status` - Current system state
- `POST /api/motor/control` - Motor control
- `POST /api/loom/release` - Loom release
- `GET /api/history` - System statistics

See [API_INTEGRATION.md](API_INTEGRATION.md) for details.

---

## Data Flow

### Real-Time Update Flow

```
Backend API
    ↓
DummyDataService.dataStream (or WebSocketService.loomDataStream)
    ↓
LoomDataNotifier receives new data
    ↓
loomDataProvider notifies listeners
    ↓
DashboardScreen re-renders affected widgets
    ↓
User sees updated data
```

### User Action Flow

```
User taps Loom Control Button (4 cm)
    ↓
Button.onPressed() callback triggered
    ↓
_releaseLoom(4) called
    ↓
ApiService.releaseLoom(lengthCm: 4) executes
    ↓
HTTP POST to /api/loom/release
    ↓
Backend releases loom and updates sensors
    ↓
Backend sends new status (automatically via stream or polling)
    ↓
UI updates with new length and total produced
```

---

## State Management Deep Dive

### Why Riverpod?

1. **Provider System**: Centralized dependency injection
2. **Scope Management**: Automatic cleanup of resources
3. **Type Safety**: Fully type-safe state management
4. **Testability**: Easy to provide mock implementations
5. **Performance**: Only rebuilds affected widgets

### Provider Types Used

#### StateNotifierProvider
```dart
final loomDataProvider = StateNotifierProvider<LoomDataNotifier, LoomData?>((ref) {
  return LoomDataNotifier(ref.watch(dummyDataServiceProvider));
});
```
- Manages complex state with business logic
- Supports side effects (like listening to streams)

#### StateProvider
```dart
final connectionStatusProvider = StateProvider<bool>((ref) {
  final data = ref.watch(loomDataProvider);
  return data?.isConnected ?? false;
});
```
- Simple reactive value derived from other providers
- Automatically updates when dependencies change

#### Provider
```dart
final failedSensorsProvider = Provider<List<int>>((ref) {
  final data = ref.watch(loomDataProvider);
  return data?.failedSensorIndices ?? [];
});
```
- Computed values without mutable state
- Cached until dependencies change

### Custom Notifier
```dart
class LoomDataNotifier extends StateNotifier<LoomData?> {
  final DummyDataService dummyDataService;

  LoomDataNotifier(this.dummyDataService) : super(null) {
    _initializeData();
  }

  void _initializeData() {
    dummyDataService.start();
    dummyDataService.dataStream.listen((data) {
      state = data;  // Notify all listeners
    });
  }
}
```

---

## Design Patterns Used

### 1. **Observer Pattern**
- StreamControllers emit data
- UI listens and rebuilds
- Implemented via Riverpod streams

### 2. **Strategy Pattern**
- Multiple implementations of data source
- Can use DummyDataService, ApiService, or WebSocketService
- Easy to swap implementations

### 3. **Builder Pattern**
- LoomData uses copyWith for immutability
- ApiResponse has factory constructors

### 4. **Repository Pattern** (Implicit)
- Services act as repositories
- Isolate data access from business logic
- Easy to test with mock services

### 5. **Decorator Pattern**
- Cards wrap content with styling
- HallSensorCard decorates sensor state

---

## Error Handling

### API Error Handling
```dart
Future<ApiResponse<LoomData>> getLoomStatus() async {
  try {
    // ... API call
    if (response.statusCode == 200) {
      return ApiResponse.success(data);
    } else {
      return ApiResponse.error('Status: ${response.statusCode}');
    }
  } catch (e) {
    return ApiResponse.error('Error: $e');
  }
}
```

### WebSocket Error Handling
```dart
_channel?.stream.listen(
  (data) { /* process */ },
  onError: (error) {
    _statusController?.add('Error: $error');
    _attemptReconnect();  // Auto-reconnect
  },
  onDone: () => _attemptReconnect(),
);
```

### UI Error Display
```dart
if (failedSensors.isNotEmpty) {
  _buildAlertSection(context, failedSensors, temperatureWarning);
}
```

---

## Performance Optimizations

### 1. **Efficient Rebuilds**
- Only widgets watching changed providers rebuild
- Grid uses `shrinkWrap` and `NeverScrollableScrollPhysics`
- StreamControllers use broadcast mode

### 2. **Memory Management**
- Providers are auto-disposed when no longer watched
- Streams are properly cleaned up in dispose()
- HTTP client connections are reused

### 3. **UI Rendering**
- Cards use const constructors where possible
- GridView renders visible items only
- Material 3 theme is cached

### 4. **Network Optimization**
- 10-second API timeout prevents hanging
- WebSocket auto-reconnects on failure
- Keep-alive connections for REST API

---

## Testing Architecture

### Unit Tests
```dart
test('LoomData.isTemperatureWarning detects high temp', () {
  final data = LoomData(
    temperature: 55,
    // ... other fields
  );
  expect(data.isTemperatureWarning, true);
});
```

### Service Tests
```dart
test('ApiService parses LoomData correctly', () async {
  // Mock HTTP client
  // Verify parsing logic
});
```

### Provider Tests
```dart
test('temperatureWarningProvider updates on temp change', () async {
  final container = ProviderContainer();
  // Test provider logic
});
```

---

## Switching Data Sources

### From Dummy to Real API

**Before**:
```dart
final loomDataProvider = StateNotifierProvider<LoomDataNotifier, LoomData?>((ref) {
  return LoomDataNotifier(ref.watch(dummyDataServiceProvider));
});
```

**After**:
```dart
final loomDataProvider = StateNotifierProvider<LoomDataNotifier, LoomData?>((ref) {
  return LoomDataNotifier(ref.watch(apiServiceProvider));
});
```

---

## Extensibility

### Adding New Features

1. **Add a sensor**:
   - Update `LoomData` model
   - Add widget in `dashboard_screen.dart`
   - Create provider if needed

2. **Add a computed value**:
   - Add Provider in `loom_providers.dart`
   - Implement logic in model
   - Use in UI via `ref.watch()`

3. **Add alerts**:
   - Create alert provider
   - Check in UI rendering
   - Display AlertSection

---

## Dependency Injection

All dependencies are managed through Riverpod:

```dart
// Services are provided here
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// They're injected into notifiers
final loomDataProvider = StateNotifierProvider<LoomDataNotifier, LoomData?>((ref) {
  return LoomDataNotifier(ref.watch(dummyDataServiceProvider));
});

// Widgets consume providers
final data = ref.watch(loomDataProvider);
```

This makes testing easy - just override the providers with mocks!

---

## Scalability Considerations

### Current Architecture Handles
- 8 sensors ✅
- 10 motors ✅
- 1-second updates ✅
- Real-time WebSocket ✅
- Mobile/Tablet UI ✅

### Future Scaling Options
- Add database for historical data
- Implement user authentication
- Add more complex analytics
- Multi-user dashboard
- Mobile app version

---

## Code Quality

- **Type Safety**: Full null safety with Dart 3.0
- **Constants**: All magic numbers are constants
- **Comments**: Code is well-documented
- **Structure**: Clear separation of concerns
- **Testing**: Easily testable architecture

---

For implementation examples, see individual files in the `lib/` directory.
