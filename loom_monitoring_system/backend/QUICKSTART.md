# ⚡ BACKEND QUICK START

Get the Node.js backend running in 5 minutes.

---

## 📋 Prerequisites

- Node.js 14+ installed
- ESP32 running `esp32_loom_controller.ino`
- ESP32 IP address known

---

## 🚀 Setup (5 minutes)

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Create Environment File
```bash
cp .env.example .env
```

### 3. Update ESP32 URL
Edit `.env` and verify:
```
ESP32_URL=http://192.168.1.100:8080
```

### 4. Create Data Directory
```bash
mkdir data
```

### 5. Start Server
```bash
npm start
```

You should see:
```
✓ Backend server running on http://localhost:3000
✓ WebSocket server ready on ws://localhost:3000
✓ Proxying to ESP32 at http://192.168.1.100:8080
```

---

## 🧪 Test It

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
```

---

## 📱 Connect Flutter App

Update `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://localhost:3000';
```

Run:
```bash
flutter run -d chrome
```

---

## 🔄 Auto-Reload (Development)

```bash
npm run dev
```

---

## 🐳 Docker

```bash
docker-compose up
```

---

## 📊 Monitor

```bash
# View logs
curl http://localhost:3000/api/logs?limit=20

# View events
curl http://localhost:3000/api/events?limit=20

# View stats
curl http://localhost:3000/api/statistics
```

---

## ⚙️ Configuration

Edit `.env` file to change:
- `PORT` - Server port (default: 3000)
- `ESP32_URL` - ESP32 address (default: http://192.168.1.100:8080)
- `NODE_ENV` - development or production
- `DB_PATH` - Database location (default: ./data/loom.db)

---

**That's it! Your backend is now running. 🎉**

Full documentation: [README.md](README.md)
