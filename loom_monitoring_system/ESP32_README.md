# 🔧 ESP32 LOOM CONTROLLER - COMPLETE FIRMWARE GUIDE

Your complete Arduino firmware solution for the industrial loom monitoring system.

---

## 📁 ESP32 Files Included

This directory contains everything you need to upload code to your ESP32:

```
├── esp32_loom_controller.ino       ← MAIN FIRMWARE (Complete system)
├── esp32_test_sketch.ino           ← TESTING SKETCH (Debug hardware)
├── ESP32_SETUP_GUIDE.md            ← Step-by-step upload instructions
├── ESP32_WIRING_GUIDE.md           ← Hardware wiring schematic
└── ESP32_README.md                 ← This file
```

---

## 🚀 Quick Start (5 Minutes)

### For Experienced Users

1. **Open Arduino IDE**
2. **Install ESP32 support**: File → Preferences → Add: `https://dl.espressif.com/dl/package_esp32_index.json`
3. **Install libraries**: 
   - ArduinoJson (Benoit Blanchon)
   - OneWire (Jim Studt)
   - DallasTemperature (Miles Burton)
4. **Edit Configuration**: Open `esp32_loom_controller.ino` and update:
   ```cpp
   const char* SSID = "YOUR_WIFI_NAME";
   const char* PASSWORD = "YOUR_WIFI_PASSWORD";
   ```
5. **Upload**: Select ESP32 Dev Module → Upload
6. **Check Serial Monitor**: Should see IP address displayed

### For Beginners

**Start here**: [ESP32_SETUP_GUIDE.md](ESP32_SETUP_GUIDE.md)

---

## 📚 Documentation Structure

### 1️⃣ **ESP32_SETUP_GUIDE.md** (Start Here!)
Complete step-by-step instructions for:
- Installing Arduino IDE
- Adding ESP32 board support
- Installing required libraries
- Configuring board settings
- Uploading firmware
- Testing API endpoints
- Connecting to Flutter app

**Read this first if you're new to ESP32.**

---

### 2️⃣ **ESP32_WIRING_GUIDE.md** (Hardware Connection)
Detailed wiring diagrams for:
- Pin assignments (GPIO mapping)
- Hall sensor connections
- Motor relay wiring
- Temperature sensor setup
- Voltage level conversion
- Complete checklist
- Component shopping list

**Read this before connecting any hardware.**

---

### 3️⃣ **esp32_loom_controller.ino** (Main Firmware)
The complete, production-ready Arduino sketch that includes:
- REST API server (4 endpoints)
- WiFi connectivity
- Sensor reading (Hall sensors, temperature)
- Motor control
- Real-time status management
- Error handling
- Comments and documentation

**This is the code you'll upload to ESP32.**

---

### 4️⃣ **esp32_test_sketch.ino** (Testing & Debugging)
Simplified test sketch for hardware debugging:
- Test individual Hall sensors
- Test individual motors
- Test temperature sensor
- System diagnostics
- Interactive menu system
- Pinout reference

**Use this if your hardware isn't working.**

---

## 🎯 What Each Sketch Does

### esp32_loom_controller.ino (MAIN)

**Provides**:
- ✅ REST API server on port 8080
- ✅ 4 API endpoints (status, motor/control, loom/release, history)
- ✅ WiFi connectivity
- ✅ Real-time sensor reading
- ✅ Motor control
- ✅ Temperature monitoring
- ✅ System statistics
- ✅ Health check endpoint

**Hardware Controlled**:
- 8 Hall sensors (GPIO 4, 5, 12, 13, 14, 15, 16, 17)
- 10 Motors (GPIO 18, 19, 21, 22, 23, 25, 26, 27, 32, 33)
- 1 Temperature sensor (GPIO 2)

**API Endpoints**:
```
GET  /api/status           → Current system status
POST /api/motor/control    → Control a motor
POST /api/loom/release     → Release loom fabric
GET  /api/history          → Production statistics
GET  /health               → Health check
```

---

### esp32_test_sketch.ino (TESTING)

**Provides**:
- ✅ Interactive menu system
- ✅ Hall sensor testing
- ✅ Motor testing (sequential activation)
- ✅ Temperature sensor testing
- ✅ System diagnostics
- ✅ Pinout information

**Use When**:
- Hardware isn't responding
- You want to debug individual components
- Before uploading the main firmware
- To verify each pin works correctly

---

## 📋 Hardware Requirements

```
1× ESP32 Development Board (ESP32-DEVKIT-V1 or similar)
8× Hall Effect Sensors (5V tolerant)
10× Relay Modules (5V, with control input)
1× Temperature Sensor (DS18B20)
1× 5V Power Supply (minimum 3A)

Passive Components:
- 10× 4.7kΩ resistors (for Hall sensor pull-down)
- 1× 4.7kΩ resistor (for temperature sensor pull-up)
- Breadboard or circuit board for wiring
- Jumper wires (various lengths)
```

---

## 🔌 Connection Diagram

```
     Hall Sensors (8)         Motor Relays (10)      Temperature (1)
            ↓                        ↓                       ↓
     [GPIO 4-17]            [GPIO 18-33]              [GPIO 2]
            │                        │                       │
            └────────────┬───────────┴───────────────────────┘
                         │
                    ┌────▼────┐
                    │   ESP32  │
                    └────┬────┘
                         │
                    ┌────▼────┐
                    │WiFi/REST │
                    │ Port 8080 │
                    └────┬────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
         Flutter App   Browser    API Client
```

---

## 🎓 Step-by-Step Usage

### Step 1: Choose Your Sketch
- **First time?** Use **esp32_test_sketch.ino** to verify hardware
- **Hardware verified?** Use **esp32_loom_controller.ino** for production

### Step 2: Prepare Hardware
1. Connect all components following [ESP32_WIRING_GUIDE.md](ESP32_WIRING_GUIDE.md)
2. Double-check all connections
3. Do NOT power on yet

### Step 3: Install Software
Follow [ESP32_SETUP_GUIDE.md](ESP32_SETUP_GUIDE.md):
1. Install Arduino IDE
2. Add ESP32 board support
3. Install required libraries
4. Configure board settings

### Step 4: Configure Code
Edit the sketch before uploading:
```cpp
// Line 11-12: Update WiFi credentials
const char* SSID = "YOUR_NETWORK";
const char* PASSWORD = "YOUR_PASSWORD";
```

### Step 5: Upload
1. Connect ESP32 via USB
2. Select correct board and COM port
3. Click Upload
4. Wait for completion

### Step 6: Test
1. Open Serial Monitor (115200 baud)
2. Press ESP32 RESET button
3. Verify WiFi connects and IP is displayed

### Step 7: Connect Flutter App
Update Flutter app with ESP32 IP:
```dart
// lib/services/api_service.dart
static const String baseUrl = 'http://192.168.1.100:8080';
```

---

## 🧪 Testing Your Setup

### Quick Health Check
```powershell
# Test if ESP32 is responding
curl http://192.168.1.100:8080/health
```

Expected response:
```json
{
  "status": "ok",
  "uptime": 45,
  "wifi": "connected",
  "ip": "192.168.1.100"
}
```

### Test Each Component
```powershell
# Get current status
curl http://192.168.1.100:8080/api/status

# Turn on Motor 0
curl -X POST http://192.168.1.100:8080/api/motor/control `
  -H "Content-Type: application/json" `
  -d '{"motorId": 0, "state": true}'

# Release 4cm loom
curl -X POST http://192.168.1.100:8080/api/loom/release `
  -H "Content-Type: application/json" `
  -d '{"lengthCm": 4.0}'

# Get history
curl http://192.168.1.100:8080/api/history
```

---

## 🚨 Troubleshooting

### Sketch Won't Upload
**Issue**: "Failed to connect to ESP32"
- Try different USB cable
- Select lower upload speed (115200)
- Hold BOOT button while uploading

### WiFi Won't Connect
**Issue**: "WiFi connection failed"
- Verify SSID and PASSWORD are correct
- Check network is 2.4GHz (not 5GHz only)
- Check WiFi password doesn't have special characters

### Sensors Not Responding
**Issue**: API returns all false/0 values
- Check wiring matches [ESP32_WIRING_GUIDE.md](ESP32_WIRING_GUIDE.md)
- Verify pull-up/pull-down resistors
- Use test sketch to debug individual sensors

### Motors Not Activating
**Issue**: POST /api/motor/control succeeds but motors don't move
- Verify relay connections
- Check relay has 5V power
- Test relay with multimeter
- Check ESP32 GPIO outputs 3.3V (test sketch)

### Can't Find ESP32 on Network
**Issue**: IP address not shown in Serial Monitor
- Check USB cable is properly connected
- Verify baud rate is 115200
- Press ESP32 RESET button
- Check WiFi router is ON

---

## 📖 API Reference

### GET /api/status
**Response**:
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

### POST /api/motor/control
**Request**:
```json
{
  "motorId": 0,
  "state": true
}
```
**Response**:
```json
{ "success": true }
```

### POST /api/loom/release
**Request**:
```json
{
  "lengthCm": 4.0
}
```
**Response**:
```json
{ "success": true }
```

### GET /api/history
**Response**:
```json
{
  "totalProduced": 5500.75,
  "uptime": 3600,
  "averageTemperature": 32.5,
  "alertCount": 2
}
```

---

## 🔐 Security Notes

⚠️ **This firmware is for development/internal use only!**

For production deployment, consider:
- Adding authentication (API key)
- Using HTTPS instead of HTTP
- Implementing rate limiting
- Adding input validation (already done)
- Using secure WiFi (WPA2/WPA3)

---

## 📞 File Quick Reference

| File | Purpose | When to Use |
|------|---------|------------|
| esp32_loom_controller.ino | Main firmware | Production code |
| esp32_test_sketch.ino | Hardware testing | Debug problems |
| ESP32_SETUP_GUIDE.md | Installation steps | First time setup |
| ESP32_WIRING_GUIDE.md | Hardware wiring | Before connecting hardware |
| ESP32_README.md | This file | Navigation & overview |

---

## ✨ Features

✅ REST API with 4 endpoints
✅ WiFi connectivity (WPA2)
✅ 8 Hall sensor inputs
✅ 10 motor control outputs
✅ Temperature monitoring
✅ System statistics
✅ Health check endpoint
✅ Real-time JSON responses
✅ Error handling
✅ Automatic reconnection
✅ Production-ready code
✅ Well-documented
✅ Easy to extend

---

## 🎯 Next Steps

### For Beginners
1. Read [ESP32_SETUP_GUIDE.md](ESP32_SETUP_GUIDE.md)
2. Read [ESP32_WIRING_GUIDE.md](ESP32_WIRING_GUIDE.md)
3. Follow wiring instructions
4. Upload test sketch
5. Run diagnostics
6. Upload main firmware

### For Experienced Users
1. Update WiFi credentials
2. Verify pin assignments match your hardware
3. Upload esp32_loom_controller.ino
4. Test with curl commands
5. Connect Flutter app

### For Production
1. Test thoroughly with test sketch
2. Secure WiFi credentials
3. Consider authentication layer
4. Monitor serial output for errors
5. Deploy with production Flutter build

---

## 📚 Additional Resources

- **ESP32 Documentation**: https://docs.espressif.com/
- **Arduino JSON**: https://arduinojson.org/
- **OneWire Library**: https://github.com/PaulStoffregen/OneWire
- **Dallas Temperature**: https://github.com/milesburton/Arduino-Temperature-Control-Library

---

## 💡 Tips & Tricks

**Tip 1**: Keep Serial Monitor open during development
- Shows real-time status updates
- Helps debug WiFi connection issues
- Displays temperature and sensor readings

**Tip 2**: Use test sketch before main firmware
- Verify each component individually
- Catch wiring errors early
- Saves debugging time

**Tip 3**: Static IP address
To assign a static IP instead of DHCP:
```cpp
// After WiFi.begin() in setup:
IPAddress ip(192, 168, 1, 100);
IPAddress gateway(192, 168, 1, 1);
IPAddress subnet(255, 255, 255, 0);
WiFi.config(ip, gateway, subnet);
```

**Tip 4**: Enable HTTPS (advanced)
Use AsyncWebServer with SSL certificates for secure communication

---

## ✅ Verification Checklist

Before deploying to production:

- [ ] All 8 Hall sensors tested and working
- [ ] All 10 motors tested and working
- [ ] Temperature sensor reading correctly
- [ ] WiFi connects reliably
- [ ] All API endpoints respond
- [ ] Flutter app connects successfully
- [ ] Sensor readings match physical state
- [ ] Motor control responds immediately
- [ ] Temperature alerts trigger at threshold
- [ ] System restarts properly after power loss

---

## 🎉 You're Ready!

Your ESP32 is now running the complete loom monitoring firmware. The Flutter app will automatically show:
- Real-time sensor data
- Motor status
- Temperature readings
- Production statistics
- System alerts

**Questions?** Check the detailed setup and wiring guides above!

---

**Last Updated**: April 20, 2026  
**Firmware Version**: 1.0  
**Compatible ESP32 Board**: ESP32-DEVKIT-V1 and compatible
