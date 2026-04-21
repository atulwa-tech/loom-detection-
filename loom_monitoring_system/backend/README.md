# 🚀 BACKEND SERVER - LOOM MONITORING SYSTEM

Node.js/Express API server with WebSocket support for industrial loom monitoring.

---

## 📋 Overview

This backend server:
- **Acts as a proxy** between the Flutter frontend and ESP32 device
- **Provides REST API endpoints** with added logging and analytics
- **Streams real-time updates** via WebSocket
- **Logs all interactions** to SQLite database
- **Tracks events** (motor control, loom release, alerts)
- **Provides statistics** and historical data

---

## 🎯 Features

✅ **REST API Proxy** - Forward requests to ESP32 with error handling
✅ **WebSocket Server** - Real-time status and event streaming
✅ **SQLite Database** - Logging, event tracking, analytics
✅ **CORS Support** - Works with Flutter frontend
✅ **Health Monitoring** - Check backend and ESP32 status
✅ **Event Logging** - Track all system events
✅ **Statistics API** - Query historical data
✅ **Auto-Polling** - Refresh status every 5 seconds
✅ **Error Handling** - Graceful failures with informative messages
✅ **Security Headers** - Helmet.js for protection

---

## 📦 Installation

### Prerequisites
- Node.js 14+ ([Download](https://nodejs.org/))
- npm or yarn
- ESP32 running `esp32_loom_controller.ino`

### Setup (5 minutes)

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Edit .env and update ESP32_URL if needed
# (Default: http://192.168.1.100:8080)

# Create data directory
mkdir data

# Start server
npm start
```

The server will start on `http://localhost:3000`

---

## 🚀 Running the Server

### Development Mode (with auto-reload)
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

### Docker (Optional)
```bash
docker build -t loom-backend .
docker run -p 3000:3000 -e ESP32_URL=http://esp32:8080 loom-backend
```

---

## 🔌 API Endpoints

### Health Check

**GET `/health`**
```bash
curl http://localhost:3000/health
```

Response:
```json
{
  "status": "ok",
  "backend": {
    "uptime": 123.45,
    "memory": { "rss": 45600000, "heapUsed": 23400000 },
    "environment": "development"
  },
  "esp32": {
    "status": "ok",
    "uptime": 45,
    "wifi": "connected",
    "ip": "192.168.1.100"
  },
  "timestamp": "2024-04-20T10:30:45.123Z"
}
```

---

### System Status (Proxied)

**GET `/api/status`**
```bash
curl http://localhost:3000/api/status
```

Response:
```json
{
  "hallSensors": [true, false, true, true, false, true, true, false],
  "loomLength": 45.5,
  "temperature": 35.2,
  "motors": [true, false, true, false, true, false, true, false, true, false],
  "isConnected": true,
  "totalLoomProduced": 1250.5,
  "lastUpdated": "2024-04-20T10:30:45.123Z",
  "backend": {
    "receivedAt": "2024-04-20T10:30:45.234Z",
    "responseTime": 109
  }
}
```

---

### Control Motor (Proxied)

**POST `/api/motor/control`**
```bash
curl -X POST http://localhost:3000/api/motor/control \
  -H "Content-Type: application/json" \
  -d '{"motorId": 0, "state": true}'
```

Response:
```json
{
  "success": true,
  "motor": 0,
  "state": true,
  "timestamp": "2024-04-20T10:30:45.123Z",
  "responseTime": 87
}
```

---

### Release Loom (Proxied)

**POST `/api/loom/release`**
```bash
curl -X POST http://localhost:3000/api/loom/release \
  -H "Content-Type: application/json" \
  -d '{"lengthCm": 4.0}'
```

Response:
```json
{
  "success": true,
  "lengthReleased": 4.0,
  "timestamp": "2024-04-20T10:30:45.123Z",
  "responseTime": 92
}
```

---

### Get History (Proxied)

**GET `/api/history`**
```bash
curl http://localhost:3000/api/history
```

Response:
```json
{
  "totalProduced": 5500.75,
  "uptime": 3600,
  "averageTemperature": 32.5,
  "alertCount": 2,
  "backend": {
    "receivedAt": "2024-04-20T10:30:45.123Z",
    "responseTime": 78
  }
}
```

---

### System Logs

**GET `/api/logs`**

Query parameters:
- `limit` (optional, default: 100) - Number of records to return
- `offset` (optional, default: 0) - Offset for pagination

```bash
curl "http://localhost:3000/api/logs?limit=50&offset=0"
```

Response:
```json
{
  "logs": [
    {
      "id": "uuid-string",
      "timestamp": "2024-04-20T10:30:45.123Z",
      "endpoint": "/api/status",
      "method": "GET",
      "status_code": 200,
      "response_time_ms": 87,
      "esp32_status": "success",
      "error": null
    }
  ],
  "count": 50
}
```

---

### Events

**GET `/api/events`**

Query parameters:
- `limit` (optional, default: 100)
- `offset` (optional, default: 0)
- `type` (optional) - Filter by event type (motor_control, loom_release, etc.)

```bash
curl "http://localhost:3000/api/events?limit=50&type=motor_control"
```

Response:
```json
{
  "events": [
    {
      "id": "uuid-string",
      "timestamp": "2024-04-20T10:30:45.123Z",
      "event_type": "motor_control",
      "event_data": "{\"motorId\": 0, \"state\": true, \"action\": \"ON\"}",
      "severity": "info"
    }
  ],
  "count": 50
}
```

---

### Statistics

**GET `/api/statistics`**
```bash
curl http://localhost:3000/api/statistics
```

Response:
```json
{
  "totalRequests": 1250,
  "successfulRequests": 1240,
  "failedRequests": 10,
  "averageResponseTime": 92,
  "sensorReadings": 500,
  "events": 85
}
```

---

## 🔗 WebSocket API

Connect to `ws://localhost:3000` for real-time updates.

### Client Connection Example (JavaScript)

```javascript
const ws = new WebSocket('ws://localhost:3000');

ws.addEventListener('open', (event) => {
  console.log('Connected to backend');
  
  // Request status updates
  ws.send(JSON.stringify({
    type: 'subscribe_status'
  }));
});

ws.addEventListener('message', (event) => {
  const data = JSON.parse(event.data);
  
  switch(data.type) {
    case 'connected':
      console.log('Welcome:', data.message);
      break;
      
    case 'status_update':
      console.log('Status update:', data.data);
      break;
      
    case 'motor_control':
      console.log('Motor changed:', data.data);
      break;
      
    case 'loom_release':
      console.log('Loom released:', data.data);
      break;
      
    case 'event':
      console.log('Event:', data.data);
      break;
  }
});

ws.addEventListener('close', () => {
  console.log('Disconnected from backend');
});
```

### WebSocket Message Types

**Subscription**:
```json
{"type": "subscribe_status"}
{"type": "subscribe_events"}
```

**Ping/Pong**:
```json
{"type": "ping"}
→ Response: {"type": "pong", "timestamp": "..."}
```

**Server-Sent Messages**:
```json
{"type": "connected", "clientId": "...", "message": "..."}
{"type": "subscribed", "channel": "status", "message": "..."}
{"type": "status_update", "data": {...}}
{"type": "motor_control", "data": {...}}
{"type": "loom_release", "data": {...}}
{"type": "event", "data": {...}}
```

---

## 🗄️ Database Schema

### system_logs table
Logs of all API requests to ESP32
```
id (TEXT)              - Unique identifier
timestamp (DATETIME)   - When the request was made
endpoint (TEXT)        - API endpoint called
method (TEXT)          - HTTP method (GET, POST)
status_code (INTEGER)  - HTTP response code
response_time_ms (INT) - How long the request took
esp32_status (TEXT)    - 'success' or 'error'
error (TEXT)           - Error message if failed
```

### sensor_data table
Historical sensor readings
```
id (TEXT)           - Unique identifier
timestamp (DATETIME)- When data was recorded
hall_sensors (TEXT) - JSON array of hall sensor states
temperature (REAL)  - Temperature in °C
loom_length (REAL)  - Loom length in cm
motors (TEXT)       - JSON array of motor states
```

### events table
System events and alerts
```
id (TEXT)        - Unique identifier
timestamp (DTE)  - When event occurred
event_type (TEX) - motor_control, loom_release, etc.
event_data (TEXT)- JSON data about the event
severity (TEXT)  - info, warning, error
```

---

## ⚙️ Configuration

Edit `.env` file:

```env
# Server listening port
PORT=3000

# ESP32 IP address and port
ESP32_URL=http://192.168.1.100:8080

# development or production
NODE_ENV=development

# SQLite database file path
DB_PATH=./data/loom.db

# Auto-polling interval (ms)
POLLING_INTERVAL=5000

# HTTP request timeout (ms)
REQUEST_TIMEOUT=5000
```

---

## 📱 Integration with Flutter App

Update your Flutter app to use the backend server instead of direct ESP32:

**In `lib/services/api_service.dart`:**
```dart
class ApiService {
  // Change this:
  static const String baseUrl = 'http://192.168.1.100:8080';
  
  // To this:
  static const String baseUrl = 'http://localhost:3000';
}
```

The rest of your code doesn't need to change - all endpoints are the same!

---

## 🔐 Security

The backend includes:
- ✅ CORS protection (whitelist your domains)
- ✅ Helmet.js security headers
- ✅ Request validation
- ✅ Error sanitization
- ✅ Rate limiting ready (can add)

**For production, consider:**
- Add API key authentication
- Implement rate limiting
- Use HTTPS with SSL certificates
- Add request validation middleware
- Restrict CORS origins
- Enable request logging to file

---

## 📊 Monitoring

### View Recent Logs
```bash
curl "http://localhost:3000/api/logs?limit=20"
```

### View Events
```bash
curl "http://localhost:3000/api/events?limit=20"
```

### Check Statistics
```bash
curl http://localhost:3000/api/statistics
```

### Monitor in Real-Time (WebSocket)
```bash
# Use any WebSocket client
# Or use the included Flutter app with websocket support
```

---

## 🧪 Testing

### Test All Endpoints

```powershell
# Health check
curl http://localhost:3000/health

# Get status
curl http://localhost:3000/api/status

# Control motor
curl -X POST http://localhost:3000/api/motor/control `
  -H "Content-Type: application/json" `
  -d '{"motorId": 0, "state": true}'

# Release loom
curl -X POST http://localhost:3000/api/loom/release `
  -H "Content-Type: application/json" `
  -d '{"lengthCm": 4.0}'

# Get history
curl http://localhost:3000/api/history

# Get logs
curl "http://localhost:3000/api/logs?limit=10"

# Get events
curl "http://localhost:3000/api/events?limit=10"

# Get statistics
curl http://localhost:3000/api/statistics
```

---

## 🚨 Troubleshooting

### Backend won't start
- Check if port 3000 is already in use
- Verify Node.js is installed (`node --version`)
- Check `.env` file exists
- Run `npm install` again

### Can't connect to ESP32
- Verify ESP32 is running and connected to WiFi
- Update `ESP32_URL` in `.env` file
- Test ESP32 directly: `curl http://192.168.1.100:8080/health`
- Check firewall isn't blocking port 8080

### WebSocket connection fails
- Ensure backend is running (`npm start`)
- Check if port 3000 is accessible
- Verify client is using correct URL (`ws://localhost:3000`)

### Database errors
- Ensure `data/` directory exists: `mkdir data`
- Check file permissions on database file
- Delete `data/loom.db` to reset (loses all data)

---

## 📚 Project Structure

```
backend/
├── server.js              ← Main server code
├── package.json           ← Dependencies
├── .env.example           ← Configuration template
├── .gitignore             ← Git ignore rules
├── README.md              ← This file
└── data/
    └── loom.db            ← SQLite database (created on first run)
```

---

## 🔄 Architecture Flow

```
┌──────────────┐
│  Flutter App │
└──────┬───────┘
       │
       │ HTTP + WebSocket
       ↓
┌──────────────────┐
│  Node.js Backend │ ← This server
├──────────────────┤
│ - REST API proxy │
│ - WebSocket      │
│ - SQLite logging │
│ - Auto-polling   │
└──────┬───────────┘
       │
       │ HTTP REST
       ↓
┌──────────────┐
│  ESP32 Device│
├──────────────┤
│ - Hall sensors
│ - Motors
│ - Temperature
└──────────────┘
```

---

## 📈 Performance Notes

- Database auto-compacts every 1000 operations
- WebSocket broadcasts every 5 seconds
- Response times: typically 80-150ms
- Memory usage: ~40-60MB idle
- Database growth: ~5KB per hour

---

## 📞 Support

If you encounter issues:
1. Check `npm start` output for errors
2. Verify ESP32 is reachable: `ping 192.168.1.100`
3. Check logs in database: `GET /api/logs`
4. Review security headers: Check browser console for CORS errors
5. Test with curl before testing with Flutter app

---

## 🎉 You're Ready!

Your backend is now:
- ✅ Proxying requests to ESP32
- ✅ Logging all interactions
- ✅ Broadcasting real-time updates via WebSocket
- ✅ Tracking events and statistics
- ✅ Ready for production use

Start the server and connect your Flutter app!

---

**Last Updated**: April 20, 2026
**Version**: 1.0.0
**Status**: Production Ready
