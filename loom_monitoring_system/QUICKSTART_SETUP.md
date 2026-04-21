# LOOM MONITORING SYSTEM - QUICK START GUIDE

## 🚀 FASTEST WAY TO RUN EVERYTHING

### Windows PowerShell (Recommended):
```powershell
.\run_all.ps1
```

### Windows Command Prompt:
```cmd
run_all.bat
```

### macOS / Linux:
```bash
chmod +x run_all.sh
./run_all.sh
```

The script will:
- ✓ Check if Node.js and Flutter are installed
- ✓ Install dependencies automatically
- ✓ Start backend on port 3000
- ✓ Start frontend on Chrome

---

## 📋 MANUAL SETUP (If scripts don't work)

### Prerequisites:
- **Node.js** (v14+): https://nodejs.org/
- **Flutter**: https://flutter.dev/ 
- **Git** (optional): https://git-scm.com/

### 1️⃣ Backend Setup:
```bash
cd backend
npm install
npm run dev
```
Backend runs on: **http://localhost:3000**

### 2️⃣ Frontend Setup (NEW TERMINAL):
```bash
flutter pub get
flutter run -d chrome
```
Frontend opens in: **Chrome Browser**

---

## 📦 WHAT'S INCLUDED

### Frontend (Flutter Web):
- Real-time sensor dashboard
- Motor control interface
- Temperature & length monitoring
- WebSocket live updates
- Material Design 3 UI

### Backend (Node.js):
- REST API endpoints
- WebSocket server
- SQLite database
- Sensor data management
- Motor control endpoints

---

## 🔌 API ENDPOINTS

```
Base URL: http://localhost:3000

GET  /api/sensors           - Get all sensor readings
GET  /api/motors            - Get motor status
POST /api/motors/:id/on     - Turn motor on
POST /api/motors/:id/off    - Turn motor off
GET  /api/statistics        - System statistics
WS   ws://localhost:3000    - Real-time WebSocket
```

---

## 🛠️ COMMON COMMANDS

```bash
# FRONTEND
flutter pub get              # Install dependencies
flutter clean                # Clean build files
flutter doctor               # Check Flutter setup
flutter analyze              # Code analysis

# BACKEND
npm install                  # Install dependencies
npm run dev                  # Run with auto-reload
npm start                    # Production run
npm run lint                 # Code linting
npm test                     # Run tests
```

---

## ❓ TROUBLESHOOTING

**Backend won't start:**
- Port 3000 in use? → Kill process or change PORT in backend/.env
- Node.js not found? → Install from https://nodejs.org/
- npm install failed? → Delete node_modules and try again

**Frontend won't connect:**
- Check backend is running first
- Verify http://localhost:3000 responds
- Clear Chrome cache: Ctrl+Shift+Delete

**Port 3000 occupied:**
- Windows: `netstat -ano | findstr :3000`
- Mac/Linux: `lsof -i :3000`
- Kill process or use different port

---

## 📚 MORE INFORMATION

- **Full documentation**: See `about.txt` for complete details
- **Project structure**: Check `ARCHITECTURE.md`
- **Backend docs**: See `backend/README.md`
- **ESP32 integration**: See `ESP32_SETUP_GUIDE.md`

---

## 💡 TIPS

✓ Keep both terminal windows visible for debugging
✓ Use browser DevTools (F12) to debug frontend
✓ Check backend console for API logs
✓ WebSocket errors show in browser console

---

**Happy monitoring! 🎉**
