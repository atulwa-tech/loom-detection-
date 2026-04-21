# 🔧 ESP32 LOOM CONTROLLER - SETUP & UPLOAD GUIDE

Complete step-by-step instructions for uploading the firmware to your ESP32.

---

## 📋 Prerequisites

### Hardware Required
- **ESP32 Development Board** (e.g., ESP32-DEVKIT-V1)
- **8× Hall Effect Sensors** (or reed switches)
- **10× Relay Modules** (5V) for motor control
- **DS18B20 Temperature Sensor** (or DHT22)
- **USB Cable** (Micro-USB or USB-C depending on your board)
- **5V Power Supply** (minimum 3A recommended)
- **Jumper Wires**

### Software Required
1. **Arduino IDE** - [Download](https://www.arduino.cc/en/software)
2. **ESP32 Board Support Package**
3. **Required Libraries**:
   - ArduinoJson (by Benoit Blanchon)
   - OneWire (by Jim Studt, Paul Stoffregen)
   - DallasTemperature (by Miles Burton, Mark Hill, et al.)

---

## 🚀 Step 1: Install Arduino IDE

1. Download from: https://www.arduino.cc/en/software
2. Install following the installer prompts
3. Launch Arduino IDE

---

## 🔌 Step 2: Add ESP32 Board Support

1. Open **File → Preferences**
2. In "Additional boards manager URLs", paste:
   ```
   https://dl.espressif.com/dl/package_esp32_index.json
   ```
3. Click **OK**
4. Go to **Tools → Board → Boards Manager**
5. Search for "ESP32"
6. Install **ESP32 by Espressif Systems** (latest version)
7. Click **Close**

---

## 📦 Step 3: Install Required Libraries

In Arduino IDE, go to **Sketch → Include Library → Manage Libraries**

Search for and install:

1. **ArduinoJson**
   - Search: "ArduinoJson"
   - Author: Benoit Blanchon
   - Version: 6.x or later
   - Click **Install**

2. **OneWire**
   - Search: "OneWire"
   - Author: Jim Studt, Paul Stoffregen
   - Click **Install**

3. **DallasTemperature**
   - Search: "DallasTemperature"
   - Author: Miles Burton, Mark Hill
   - Click **Install**

---

## ⚙️ Step 4: Configure Arduino IDE for ESP32

1. Connect ESP32 to computer via USB cable
2. Go to **Tools** menu and configure:
   - **Board**: ESP32 → "ESP32 Dev Module"
   - **Flash Frequency**: "80 MHz"
   - **Flash Mode**: "QIO"
   - **Flash Size**: "4MB"
   - **Partition Scheme**: "Default 4MB with spiffs"
   - **Core Debug Level**: "None"
   - **PSRAM**: "Disabled"
   - **Port**: Select your COM port (e.g., COM3, COM4, /dev/ttyUSB0)
   - **Upload Speed**: "921600"

---

## 📝 Step 5: Configure WiFi Credentials

1. Open the sketch file: `esp32_loom_controller.ino`
2. Find these lines (near top):
   ```cpp
   const char* SSID = "YOUR_WIFI_SSID";
   const char* PASSWORD = "YOUR_WIFI_PASSWORD";
   ```
3. Replace with your actual WiFi credentials:
   ```cpp
   const char* SSID = "My_WiFi_Network";
   const char* PASSWORD = "MySecurePassword123";
   ```
4. **Save** the file (Ctrl+S or Cmd+S)

---

## 🔌 Step 6: Connect Hardware

### Pin Configuration

```
HALL SENSORS (INPUT):
- Hall Sensor 0 → GPIO 4
- Hall Sensor 1 → GPIO 5
- Hall Sensor 2 → GPIO 12
- Hall Sensor 3 → GPIO 13
- Hall Sensor 4 → GPIO 14
- Hall Sensor 5 → GPIO 15
- Hall Sensor 6 → GPIO 16
- Hall Sensor 7 → GPIO 17

MOTOR CONTROL (OUTPUT):
- Motor 0 → GPIO 18
- Motor 1 → GPIO 19
- Motor 2 → GPIO 21
- Motor 3 → GPIO 22
- Motor 4 → GPIO 23
- Motor 5 → GPIO 25
- Motor 6 → GPIO 26
- Motor 7 → GPIO 27
- Motor 8 → GPIO 32
- Motor 9 → GPIO 33

TEMPERATURE SENSOR (INPUT):
- DS18B20 → GPIO 2 (with 4.7kΩ pull-up resistor)

POWER:
- GND → Power supply GND, all relay GND, all sensor GND
- 5V → Relay 5V in, Hall sensor 5V (with resistor divider for 3.3V)
- ESP32 3.3V → Temperature sensor VCC
```

### Wiring Example

```
Hall Sensor (5V type):
  +5V ─→ Hall Sensor VCC
  GND ─→ Hall Sensor GND
  OUT ─→ [4.7kΩ pulldown to GND] → ESP32 GPIO (e.g., GPIO 4)

Motor Relay (5V type):
  +5V ─→ Relay VCC
  GND ─→ Relay GND
  IN  ─→ ESP32 GPIO (e.g., GPIO 18)

Temperature Sensor (DS18B20):
  VCC (+3.3V) ─→ [4.7kΩ pull-up to 3.3V] → DQ
  GND ─→ GND
  DQ  ─→ ESP32 GPIO 2
```

**⚠️ IMPORTANT**: 
- Use voltage dividers or logic level shifters if your sensors output 5V
- Always use pull-up/pull-down resistors for digital sensors
- Ground all devices properly to prevent noise and errors

---

## 🖱️ Step 7: Upload the Sketch

1. **Open** `esp32_loom_controller.ino` in Arduino IDE
2. Verify the code compiles: **Sketch → Verify/Compile** (Ctrl+R)
3. Upload to ESP32: **Sketch → Upload** (Ctrl+U)
4. Wait for upload to complete (you'll see: "Writing at 0x...")
5. When done, you'll see:
   ```
   Leaving... Hard resetting via RTS pin...
   ```

---

## 📡 Step 8: Verify Connection

1. Open **Tools → Serial Monitor**
2. Set baud rate to **115200**
3. Press ESP32 **RST** button
4. You should see:
   ```
   =======================================
   ESP32 LOOM MONITORING SYSTEM
   =======================================
   ✓ Hall sensors configured
   ✓ Motor control pins configured
   ✓ Temperature sensor initialized
   Connecting to WiFi: My_WiFi_Network
   ....
   ✓ WiFi connected!
   IP Address: 192.168.1.100
   Local Port: 8080
   ✓ Web server started on port 8080
   =======================================
   ```

**Copy the IP Address** - you'll use this to connect from Flutter app!

---

## 🧪 Step 9: Test API Endpoints

### Using curl (Command Prompt or PowerShell):

Replace `192.168.1.100` with your ESP32's actual IP address.

**1. Check Health:**
```powershell
curl http://192.168.1.100:8080/health
```

**2. Get Status:**
```powershell
curl http://192.168.1.100:8080/api/status
```

**3. Turn on Motor 0:**
```powershell
curl -X POST http://192.168.1.100:8080/api/motor/control `
  -H "Content-Type: application/json" `
  -d '{"motorId": 0, "state": true}'
```

**4. Release 4cm of Loom:**
```powershell
curl -X POST http://192.168.1.100:8080/api/loom/release `
  -H "Content-Type: application/json" `
  -d '{"lengthCm": 4.0}'
```

**5. Get History:**
```powershell
curl http://192.168.1.100:8080/api/history
```

---

## 📱 Step 10: Connect Flutter App

1. Open the Flutter app file: `lib/services/api_service.dart`
2. Find the line:
   ```dart
   static const String baseUrl = 'http://localhost:8080';
   ```
3. Replace with your ESP32 IP address:
   ```dart
   static const String baseUrl = 'http://192.168.1.100:8080';
   ```
4. Save and run the Flutter app:
   ```bash
   flutter run -d chrome
   ```

The app should now connect to your ESP32! 🎉

---

## 🐛 Troubleshooting

### ESP32 Not Uploading
- **Issue**: "Failed to connect to ESP32"
- **Solution**:
  - Try a different USB cable
  - Install CH340 drivers (if using cheap boards)
  - Hold BOOT button while uploading
  - Try lower upload speed (115200)

### WiFi Connection Fails
- **Issue**: "WiFi connection failed"
- **Solution**:
  - Verify SSID and PASSWORD are correct (case-sensitive)
  - Check WiFi network is 2.4GHz (not 5GHz only)
  - Move ESP32 closer to router
  - Check if WiFi has MAC filtering enabled

### Cannot Reach API Endpoints
- **Issue**: "Connection refused" from Flutter app
- **Solution**:
  - Verify ESP32 and phone/computer are on same WiFi
  - Check firewall isn't blocking port 8080
  - Verify IP address in Flutter app matches Serial Monitor output
  - Restart ESP32 by pressing RST button

### Temperature Sensor Not Reading
- **Issue**: "temp > -127 or temp < 85" error
- **Solution**:
  - Check 4.7kΩ pull-up resistor is properly connected
  - Verify DS18B20 VCC, GND, DQ connections
  - Test with simplified OneWire example

### Motors Not Responding
- **Issue**: POST request succeeds but motors don't move
- **Solution**:
  - Check relay connections to GPIO pins
  - Verify relay has 5V power
  - Test relay with simple digitalWrite(pin, HIGH)
  - Check motor/motor is actually connected to relay

---

## 📚 Useful Resources

- **ESP32 Pinout**: https://www.espressif.com/sites/default/files/documentation/esp32_datasheet_en.pdf
- **Arduino JSON Guide**: https://arduinojson.org/
- **OneWire Library**: https://github.com/PaulStoffregen/OneWire
- **Dallas Temperature**: https://github.com/milesburton/Arduino-Temperature-Control-Library

---

## 🔐 Security Recommendations (Production)

1. **Add Authentication**: Implement API key or OAuth2
2. **Use HTTPS**: Requires self-signed certificate
3. **Rate Limiting**: Prevent DoS attacks
4. **Input Validation**: Already implemented in sketch
5. **Secure WiFi**: Use WPA2/WPA3 encryption
6. **Regular Updates**: Keep libraries and firmware updated

---

## 📞 Support

If you encounter issues:
1. Check Serial Monitor output (Tools → Serial Monitor)
2. Verify all pin connections match the pinout above
3. Test each component separately
4. Review Arduino IDE error messages
5. Check if you're using correct library versions

---

**You're all set! 🚀 Your ESP32 is ready to control your loom system.**
