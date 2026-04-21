# 🔗 COMPLETE SYSTEM INTEGRATION GUIDE

Step-by-step guide to integrate all three components: Flutter Frontend, Node.js Backend, and ESP32 Device.

---

## 📋 Overview

Your system has three layers:

```
Flutter App (Frontend)
        ↓ HTTP + WebSocket
Node.js Backend (API Server)
        ↓ HTTP REST
ESP32 (Microcontroller)
```

---

## ✅ Prerequisites Checklist

Before starting, ensure you have:

- [ ] ESP32 with `esp32_loom_controller.ino` uploaded and running
- [ ] ESP32 IP address (visible in Serial Monitor)
- [ ] Node.js 14+ installed on your computer
- [ ] Flutter SDK installed
- [ ] WiFi network set up and stable

---

## 🚀 STEP 1: Start ESP32

### 1.1 Verify ESP32 is Running

Open Serial Monitor in Arduino IDE:
- Baud rate: 115200
- Press ESP32 RESET button
- You should see:
```
=======================================
ESP32 LOOM MONITORING SYSTEM
=======================================
...
✓ WiFi connected!
IP Address: 192.168.1.100
Local Port: 8080
✓ Web server started on port 8080
```

**Note down the IP address** (e.g., 192.168.1.100)

### 1.2 Quick Test

```bash
curl http://192.168.1.100:8080/health
```

Should return:
```json
{"status": "ok", "uptime": 45, ...}
```

✅ **ESP32 is ready!**

---

## 🚀 STEP 2: Start Backend Server

### 2.1 Navigate to Backend Directory

```bash
cd backend
```

### 2.2 Install Dependencies

```bash
npm install
```

### 2.3 Configure ESP32 URL

Edit `.env` file:
```
ESP32_URL=http://192.168.1.100:8080
PORT=3000
```

Replace `192.168.1.100` with your actual ESP32 IP!

### 2.4 Create Data Directory

```bash
mkdir data
```

### 2.5 Start the Server

```bash
npm start
```

You should see:
```
✓ Backend server running on http://localhost:3000
✓ WebSocket server ready on ws://localhost:3000
✓ Proxying to ESP32 at http://192.168.1.100:8080
```

### 2.6 Test Backend

In another terminal:
```powershell
# Health check
curl http://localhost:3000/health

# Get status
curl http://localhost:3000/api/status
```

Should return data from ESP32!

✅ **Backend is ready!**

---

## 🚀 STEP 3: Update Flutter App

### 3.1 Update API URL

Open: `lib/services/api_service.dart`

Change this line (currently pointing to ESP32):
```dart
// OLD:
static const String baseUrl = 'http://192.168.1.100:8080';

// NEW:
static const String baseUrl = 'http://localhost:3000';
```

### 3.2 (Optional) Add WebSocket Support

If you want real-time updates via WebSocket, copy the client code from:
`backend/flutter_client.dart` into your Flutter project

Or use your existing implementation

### 3.3 Run Flutter App

```bash
cd ..  # Go back to project root
flutter run -d chrome
```

The app should now:
- ✅ Connect to backend on `localhost:3000`
- ✅ Backend proxies requests to ESP32
- ✅ Display real-time data
- ✅ Receive WebSocket updates every 5 seconds

---

## 🧪 COMPLETE SYSTEM TEST

### Test 1: Check All Health

```bash
# Terminal 1: Check ESP32
curl http://192.168.1.100:8080/health

# Terminal 2: Check Backend
curl http://localhost:3000/health

# Terminal 3: Check Flutter App
# Open http://localhost:port in browser
```

All three should respond successfully.

### Test 2: Control Motor

```bash
curl -X POST http://localhost:3000/api/motor/control \
  -H "Content-Type: application/json" \
  -d '{"motorId": 0, "state": true}'
```

Expected response:
```json
{"success": true, "motor": 0, "state": true, ...}
```

**Verify**: Motor 0 should activate on ESP32 (relay should click)

### Test 3: Release Loom

```bash
curl -X POST http://localhost:3000/api/loom/release \
  -H "Content-Type: application/json" \
  -d '{"lengthCm": 4.0}'
```

Expected response:
```json
{"success": true, "lengthReleased": 4.0, ...}
```

**Verify**: Loom should release 4cm

### Test 4: Real-time Updates

1. Keep Flutter app running
2. Control motor from curl command above
3. **Verify**: Flutter app shows motor state change immediately

### Test 5: Database Logging

```bash
curl "http://localhost:3000/api/logs?limit=10"
```

Should show recent requests

✅ **All systems working together!**

---

## 📱 Using the System

Now your complete system is integrated:

### From Flutter App:
1. **View Status** - Real-time sensor readings
2. **Control Motors** - Turn motors ON/OFF
3. **Release Loom** - Release fabric by length
4. **View History** - Production statistics
5. **Real-time Updates** - WebSocket streaming

### From Backend API (curl):
1. **GET** `/api/status` - Current state
2. **POST** `/api/motor/control` - Control motors
3. **POST** `/api/loom/release` - Release loom
4. **GET** `/api/logs` - View request history
5. **GET** `/api/events` - View system events

### From ESP32:
- Direct REST API available at `http://192.168.1.100:8080`
- Can bypass backend if needed

---

## 🔄 Typical Workflow

### Normal Operation

```
1. Flutter App starts
   ├─→ Connects to Backend (localhost:3000)
   └─→ Backend connects to ESP32 (192.168.1.100:8080)

2. Every 5 seconds:
   ├─→ Backend polls ESP32 for status
   ├─→ Logs data to SQLite database
   └─→ Broadcasts to all WebSocket clients

3. When user controls motor:
   ├─→ Flutter app sends POST to Backend
   ├─→ Backend validates request
   ├─→ Backend sends to ESP32
   ├─→ Creates event in database
   ├─→ Broadcasts event to all clients
   └─→ All apps update UI instantly

4. Real-time monitoring continues
   ├─→ WebSocket streams status updates
   ├─→ App displays changes
   └─→ Events logged in database
```

### If Backend Goes Down

```
Flutter App ──X─→ Backend (Can't reach)
              │
              └─→ Show error message
              
Option: Direct to ESP32
Flutter App ──→ ESP32 (Direct connection)
              └─→ Basic functionality works
```

### If ESP32 Goes Down

```
Backend ──X─→ ESP32 (Can't reach)
   │
   ├─→ Return error to client
   ├─→ Log failed request
   └─→ Keep showing last known state
   
Option: Restart ESP32
   ├─→ Backend automatically reconnects
   ├─→ Data resumes
   └─→ App updates
```

---

## 🐛 Troubleshooting

### "Cannot reach ESP32 from Backend"

```bash
# Check ESP32 is running
curl http://192.168.1.100:8080/health

# Update .env with correct IP
ESP32_URL=http://YOUR_ACTUAL_IP:8080

# Restart backend
npm start
```

### "Flutter app shows connection error"

```bash
# Check backend is running
curl http://localhost:3000/health

# Check Flutter app API URL
# lib/services/api_service.dart should have:
# static const String baseUrl = 'http://localhost:3000';

# Make sure backend port 3000 is accessible
netstat -an | findstr :3000
```

### "Motor doesn't respond to command"

```bash
# 1. Check ESP32 directly
curl -X POST http://192.168.1.100:8080/api/motor/control \
  -H "Content-Type: application/json" \
  -d '{"motorId": 0, "state": true}'

# 2. Check backend proxying
curl -X POST http://localhost:3000/api/motor/control \
  -H "Content-Type: application/json" \
  -d '{"motorId": 0, "state": true}'

# 3. Check wiring on ESP32 (see ESP32_WIRING_GUIDE.md)
```

### "WebSocket not updating"

```bash
# 1. Check if connected
# Monitor Flutter console logs

# 2. Check backend WebSocket
# ws://localhost:3000 should be open

# 3. Restart backend
npm start

# 4. Refresh Flutter app
```

---

## 📊 Monitoring

### Check System Status

```bash
# Backend health
curl http://localhost:3000/health

# ESP32 health
curl http://192.168.1.100:8080/health

# Recent requests
curl "http://localhost:3000/api/logs?limit=20"

# Recent events
curl "http://localhost:3000/api/events?limit=20"

# Statistics
curl http://localhost:3000/api/statistics
```

### View Logs in Real-time

```bash
# Terminal 1: Backend logs
npm start

# Terminal 2: View request logs
watch 'curl http://localhost:3000/api/logs?limit=10'

# Terminal 3: View events
watch 'curl http://localhost:3000/api/events?limit=10'
```

---

## 🚀 Deployment

### Development Setup (Local)
- Backend: `http://localhost:3000`
- ESP32: `http://192.168.1.100:8080` (local network)
- Flutter: `flutter run -d chrome`

### Production Setup (Cloud)
```
1. Deploy backend to cloud (Docker, AWS, Heroku)
   - Update ESP32_URL to your device server
   - Set NODE_ENV=production
   - Enable HTTPS

2. Update Flutter app
   - Change baseUrl to cloud backend
   - Build for production

3. Deploy Flutter frontend
   - Web: Firebase, Netlify, GitHub Pages
   - Mobile: App Store, Play Store
   - Desktop: Create installer
```

### Docker Deployment
```bash
cd backend

# Build image
docker build -t loom-backend .

# Run container
docker run -p 3000:3000 \
  -e ESP32_URL=http://192.168.1.100:8080 \
  loom-backend
```

Or use Docker Compose:
```bash
docker-compose up
```

---

## 📝 Configuration Reference

### Backend (.env)
```
PORT=3000
ESP32_URL=http://192.168.1.100:8080
NODE_ENV=development
DB_PATH=./data/loom.db
```

### Flutter (lib/services/api_service.dart)
```dart
static const String baseUrl = 'http://localhost:3000';
```

### ESP32 (esp32_loom_controller.ino)
```cpp
const char* SSID = "YOUR_WIFI";
const char* PASSWORD = "YOUR_PASSWORD";
const int PORT = 8080;
```

---

## 🎉 Success Criteria

Your system is fully integrated when:

- ✅ ESP32 is running and showing IP address
- ✅ Backend is running on port 3000
- ✅ `curl http://localhost:3000/health` returns 200
- ✅ Flutter app connects to backend without errors
- ✅ Flutter app displays sensor data
- ✅ Controlling motor from app works
- ✅ WebSocket updates are received (if implemented)
- ✅ Backend logs show all requests
- ✅ Database has event entries

---

## 📞 Quick Reference

```bash
# Start ESP32
# Upload esp32_loom_controller.ino via Arduino IDE
# Check Serial Monitor for IP

# Start Backend
cd backend
npm install
cp .env.example .env
# Edit .env with ESP32 IP
mkdir data
npm start

# Run Flutter
# Update lib/services/api_service.dart
flutter run -d chrome

# Test All Components
curl http://192.168.1.100:8080/health      # ESP32
curl http://localhost:3000/health           # Backend
# Open http://localhost:port in browser for Flutter

# Control System
curl -X POST http://localhost:3000/api/motor/control \
  -H "Content-Type: application/json" \
  -d '{"motorId": 0, "state": true}'
```

---

**🎯 You have a complete, integrated IoT system!**

- Frontend: Flutter app with beautiful UI
- Backend: Node.js API with database logging
- Device: ESP32 with hardware control
- Integration: All three communicating seamlessly
- Monitoring: Real-time updates and event logging

**Last Updated**: April 20, 2026
**Version**: 1.0
**Status**: Production Ready
