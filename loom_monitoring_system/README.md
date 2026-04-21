# Loom Monitoring System - Flutter Web Frontend

A professional, industrial-grade Flutter web frontend for monitoring and controlling an automated loom system with ESP32 microcontroller backend.

## Project Overview

This Flutter web application provides real-time monitoring and control of:
- **8 Hall Sensors** - Detect loom movement (ON/OFF status)
- **1 Length Sensor** - Measure loom length in cm
- **1 Temperature Sensor** - Monitor machine temperature
- **10 Motors** - Control loom storage and output
- **Real-time Dashboard** - Live updating UI with alerts and statistics

## Features

### Dashboard Screen
- ✅ Hall Sensors Grid (2x4 layout) with color-coded status
- ✅ Real-time Loom Length display
- ✅ Temperature monitoring with warning alerts
- ✅ Motor Control section (visual toggle)
- ✅ 3 Loom Release Control Buttons (2cm, 4cm, 8cm)
- ✅ System Status Indicator (Connected/Disconnected)
- ✅ Failed Sensor Alerts
- ✅ Temperature Warning Alerts
- ✅ Total Loom Produced Counter
- ✅ System Statistics Panel

### UI/UX Highlights
- Material Design 3 theming
- Professional industrial color scheme
- Responsive grid-based layout
- Real-time data updates (1-second refresh)
- Loading indicators
- Smooth transitions and animations
- Mobile & tablet optimized

### Architecture
- **State Management**: Flutter Riverpod
- **API Communication**: REST API with HTTP + WebSocket support
- **Code Structure**: Clean separation of concerns
  - `models/` - Data models
  - `services/` - API & data services
  - `providers/` - State management
  - `screens/` - UI screens
  - `widgets/` - Reusable UI components
  - `theme/` - Theming and styling

## Project Structure

```
loom_monitoring_system/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/
│   │   ├── loom_data.dart        # LoomData model
│   │   ├── api_response.dart     # API response models
│   │   └── index.dart
│   ├── services/
│   │   ├── api_service.dart      # REST API client
│   │   ├── websocket_service.dart# WebSocket client
│   │   ├── dummy_data_service.dart# Testing dummy data
│   │   └── index.dart
│   ├── providers/
│   │   ├── loom_providers.dart   # Riverpod providers
│   │   └── index.dart
│   ├── screens/
│   │   ├── dashboard_screen.dart # Main dashboard
│   │   └── index.dart
│   ├── widgets/
│   │   ├── custom_widgets.dart   # Reusable components
│   │   └── index.dart
│   ├── theme/
│   │   └── app_theme.dart        # Material 3 theme config
│   └── utils/
├── test/                         # Unit tests
├── pubspec.yaml                  # Dependencies
└── README.md                     # Documentation
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0                # State management
  http: ^1.1.0                    # REST API calls
  web_socket_channel: ^2.4.0      # WebSocket communication
  intl: ^0.19.0                   # Date/time formatting
  google_fonts: ^6.0.0            # Custom fonts
  flutter_riverpod: ^2.4.0        # Advanced state management
```

## Getting Started

### Prerequisites
- Flutter 3.10+ installed
- Dart 3.0+
- A running backend API server (ESP32 or REST server)

### Installation

1. **Clone the repository**
   ```bash
   cd loom_monitoring_system
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For web
   flutter run -d chrome
   
   # Or for desktop
   flutter run -d windows
   flutter run -d linux
   flutter run -d macos
   ```

## API Integration

### Backend Requirements

Your backend API (ESP32 or REST server) should implement these endpoints:

#### 1. **GET /api/status** - Fetch current system status
```json
Response:
{
  "hallSensors": [true, false, true, true, false, true, true, false],
  "loomLength": 45.5,
  "temperature": 35.2,
  "motors": [true, false, true, false, true, false, true, false, true, false],
  "isConnected": true,
  "totalLoomProduced": 1250.5,
  "lastUpdated": "2024-04-20T10:30:45.123Z"
}
```

#### 2. **POST /api/motor/control** - Control a motor
```json
Request:
{
  "motorId": 0,
  "state": true
}

Response:
{ "success": true }
```

#### 3. **POST /api/loom/release** - Release loom for specified length
```json
Request:
{
  "lengthCm": 4.0
}

Response:
{ "success": true }
```

#### 4. **GET /api/history** - Get system history
```json
Response:
{
  "totalProduced": 5500.75,
  "uptime": 3600,
  "averageTemperature": 32.5,
  "alertCount": 2
}
```

### WebSocket Support (Optional)

For real-time data streaming, implement WebSocket at `ws://localhost:8080/ws`

The app will receive JSON messages in the same format as `/api/status` endpoint.

## Configuration

### Change API Base URL

Edit `lib/services/api_service.dart`:
```dart
static const String _baseUrl = 'http://your-api-server:8080/api';
```

### Change WebSocket URL

Edit `lib/services/websocket_service.dart`:
```dart
static const String _wsUrl = 'ws://your-api-server:8080/ws';
```

### Change Temperature Warning Threshold

Edit `lib/models/loom_data.dart`:
```dart
bool get isTemperatureWarning => temperature > 50; // Change 50 to your threshold
```

### Testing with Dummy Data

The app is configured to use dummy data by default for testing.

## Build for Production

### Web
```bash
flutter build web --release
```

### Desktop
```bash
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## Performance Optimization

- **Update Rate**: 1 second refresh cycle
- **Real-time Stream**: Uses Riverpod for efficient rebuilds
- **Widget Optimization**: Consumer widgets only rebuild on relevant state changes
- **Responsive Design**: Works on desktop, tablet, and mobile

## License

MIT License
