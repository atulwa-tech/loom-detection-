# Quick Start Guide

Get up and running with the Loom Monitoring System in minutes!

## 1. Prerequisites

- Flutter 3.10+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Dart 3.0+ (comes with Flutter)
- A code editor (VS Code, Android Studio, or IntelliJ)

## 2. Installation

### Clone or Download
```bash
cd loom_monitoring_system
```

### Install Dependencies
```bash
flutter pub get
```

This downloads all required packages including:
- `provider` - State management
- `http` - REST API communication
- `web_socket_channel` - WebSocket support
- `google_fonts` - Custom fonts
- `flutter_riverpod` - Advanced state management

## 3. Run the App

### Option A: Run with Dummy Data (No Backend Required)
```bash
flutter run
```

Choose a device:
- `chrome` - Run in web browser
- `windows` - Run on Windows
- `macos` - Run on macOS
- `linux` - Run on Linux

Example:
```bash
flutter run -d chrome
```

### Option B: Run on Specific Device
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d chrome
```

## 4. Testing

The app comes with **dummy data enabled by default**, so you can test immediately without a backend!

The dummy data service:
- ✅ Generates realistic sensor data
- ✅ Updates every 1 second
- ✅ Simulates temperature changes
- ✅ Toggles sensors randomly
- ✅ Perfect for UI testing

## 5. Connect to Your Backend (Optional)

When ready to connect your ESP32 or backend API:

### Step 1: Update API URL
Edit `lib/services/api_service.dart`:
```dart
static const String _baseUrl = 'http://your-backend-ip:8080/api';
```

### Step 2: Update WebSocket URL
Edit `lib/services/websocket_service.dart`:
```dart
static const String _wsUrl = 'ws://your-backend-ip:8080/ws';
```

### Step 3: Verify Backend
Ensure your backend implements the required endpoints:
- `GET /api/status` - Returns current system status
- `POST /api/motor/control` - Control motors
- `POST /api/loom/release` - Release loom

See [API_INTEGRATION.md](API_INTEGRATION.md) for detailed API specification.

### Step 4: Test Connection
```bash
flutter run -d chrome
```

If connection fails, check:
- Backend is running
- API URL is correct
- Firewall/Network allows connections
- Browser console (F12) for errors

## 6. Build for Production

### Web
```bash
flutter build web --release
```
Output: `build/web/` - Ready to deploy to any web server

### Windows
```bash
flutter build windows --release
```
Output: `build/windows/runner/Release/loom_monitoring_system.exe`

### macOS
```bash
flutter build macos --release
```
Output: `build/macos/Build/Products/Release/loom_monitoring_system.app`

### Linux
```bash
flutter build linux --release
```
Output: `build/linux/x64/release/bundle/loom_monitoring_system`

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment instructions.

## 7. Project Structure

```
lib/
├── main.dart                     # App entry point
├── models/
│   ├── loom_data.dart           # System status data model
│   └── api_response.dart        # API response models
├── services/
│   ├── api_service.dart         # REST API client
│   ├── websocket_service.dart   # WebSocket client
│   └── dummy_data_service.dart  # Testing dummy data
├── providers/
│   └── loom_providers.dart      # State management (Riverpod)
├── screens/
│   └── dashboard_screen.dart    # Main dashboard
├── widgets/
│   └── custom_widgets.dart      # Reusable UI components
└── theme/
    └── app_theme.dart           # Material 3 theme
```

## 8. Key Files to Know

| File | Purpose |
|------|---------|
| [lib/main.dart](lib/main.dart) | App initialization & routing |
| [lib/models/loom_data.dart](lib/models/loom_data.dart) | System data structure |
| [lib/services/dummy_data_service.dart](lib/services/dummy_data_service.dart) | Dummy data for testing |
| [lib/services/api_service.dart](lib/services/api_service.dart) | Real API integration |
| [lib/providers/loom_providers.dart](lib/providers/loom_providers.dart) | State management |
| [lib/screens/dashboard_screen.dart](lib/screens/dashboard_screen.dart) | Main UI |
| [lib/widgets/custom_widgets.dart](lib/widgets/custom_widgets.dart) | UI components |
| [lib/theme/app_theme.dart](lib/theme/app_theme.dart) | Theme configuration |

## 9. Testing with cURL (Backend Testing)

Before connecting Flutter to your backend, test API endpoints with cURL:

### Get Status
```bash
curl http://localhost:8080/api/status
```

### Control Motor
```bash
curl -X POST http://localhost:8080/api/motor/control \
  -H "Content-Type: application/json" \
  -d '{"motorId": 0, "state": true}'
```

### Release Loom
```bash
curl -X POST http://localhost:8080/api/loom/release \
  -H "Content-Type: application/json" \
  -d '{"lengthCm": 4.0}'
```

## 10. Common Commands

```bash
# Get latest dependencies
flutter pub get

# Upgrade all dependencies
flutter pub upgrade

# Run app in debug mode
flutter run

# Run app in release mode
flutter run --release

# Run app in profile mode (for performance testing)
flutter run --profile

# Build for web
flutter build web --release

# Clean build artifacts
flutter clean

# Analyze code
flutter analyze

# Format code
dart format lib/

# Run tests
flutter test
```

## 11. Development Tips

### Hot Reload
Press `r` in terminal while app is running to hot reload changes instantly.

### DevTools
```bash
flutter pub global activate devtools
devtools
```

### Debug Mode
- Press `d` for additional debug info
- Press `w` for widget inspector
- Use browser DevTools (F12) for web

### Profile App Size
```bash
flutter build web --analyze-size
```

## 12. Troubleshooting

### App Won't Start
```bash
flutter clean
flutter pub get
flutter run
```

### Network Errors
- Check if backend API is running
- Verify API URL in services
- Check browser console (F12) for CORS errors

### Missing Dependencies
```bash
flutter pub get
flutter pub upgrade
flutter clean
flutter pub get
```

### Port Already in Use
If port 8080 is taken, change it in your backend configuration.

## 13. Next Steps

1. **Understand the Architecture**: Read the code comments in `lib/main.dart`
2. **Modify the Dashboard**: Edit `lib/screens/dashboard_screen.dart`
3. **Customize Colors**: Edit `lib/theme/app_theme.dart`
4. **Connect Your Backend**: Follow Section 5 above
5. **Deploy**: See [DEPLOYMENT.md](DEPLOYMENT.md)

## 14. Need Help?

- 📖 [Flutter Documentation](https://flutter.dev/docs)
- 🔗 [API Integration Guide](API_INTEGRATION.md)
- 🚀 [Deployment Guide](DEPLOYMENT.md)
- 📋 [Full README](README.md)
- 📊 [Sample Data](SAMPLE_DATA.json)

## 15. Example Backend Responses

Your backend needs to return data in this format:

```json
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

See [API_INTEGRATION.md](API_INTEGRATION.md) for complete API specification.

---

**Ready to go!** Run `flutter run -d chrome` and start monitoring your loom system! 🎯
