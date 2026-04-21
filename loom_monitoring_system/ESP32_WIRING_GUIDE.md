# 🔗 ESP32 HARDWARE WIRING SCHEMATIC

Quick visual reference for connecting your hardware to the ESP32.

---

## 📊 Pin Assignments

### Hall Sensors (Input) - GPIO 4, 5, 12, 13, 14, 15, 16, 17

```
Hall Sensor 0 → GPIO 4
Hall Sensor 1 → GPIO 5
Hall Sensor 2 → GPIO 12
Hall Sensor 3 → GPIO 13
Hall Sensor 4 → GPIO 14
Hall Sensor 5 → GPIO 15
Hall Sensor 6 → GPIO 16
Hall Sensor 7 → GPIO 17
```

### Motor Relays (Output) - GPIO 18, 19, 21, 22, 23, 25, 26, 27, 32, 33

```
Motor 0 → GPIO 18
Motor 1 → GPIO 19
Motor 2 → GPIO 21
Motor 3 → GPIO 22
Motor 4 → GPIO 23
Motor 5 → GPIO 25
Motor 6 → GPIO 26
Motor 7 → GPIO 27
Motor 8 → GPIO 32
Motor 9 → GPIO 33
```

### Temperature Sensor (Input) - GPIO 2

```
DS18B20 → GPIO 2 (with 4.7kΩ pull-up to 3.3V)
```

---

## 🔌 Wiring Diagram (Text Format)

### Single Hall Sensor Connection

```
┌─────────────────────────────────────────┐
│         5V Hall Sensor                   │
├─────────────────────────────────────────┤
│  VCC (5V)    GND      OUT (Signal)      │
│    │         │           │              │
│    │         │           │              │
│    ↓         ↓           ↓              │
└────┼─────────┼───────────┼──────────────┘
     │         │           │
     │         │           ├──[4.7kΩ]──┐
     │         │           │           │
     └─────────┼─────(5V)──┤        (3.3V)
               │           │           │
               │           └───────────┼──→ ESP32 GPIO (4-17)
               │                       │
               └──────────────────────→ ESP32 GND
```

### Motor Relay Connection

```
┌──────────────────────────────────────────┐
│       5V Relay Module                     │
├──────────────────────────────────────────┤
│  IN    VCC    GND   │   COM   NO   NC   │
│  │      │      │    │    │     │    │   │
│  │      │      │    │    │     │    │   │
│  ↓      ↓      ↓    │    ↓     ↓    ↓   │
└──┼──────┼──────┼────┼────┼─────┼────┼───┘
   │      │      │    │    │     │    │
   │      │      │    │    │     │    │
   │      └──────┼─────────────────────┘  (Motor COM)
   │             │    │
   │             │    └──[Motor Coil]──┐
   │             │                       │
   └─(ESP32 GPIO)                        │
                 │                       │
         ESP32 GND ─ (5V GND) ─── Motor─┘
```

### Temperature Sensor (DS18B20)

```
        DS18B20 Temperature Sensor
        ┌────────────────────┐
        │ VCC    DQ    GND   │
        │  │      │      │   │
        │  │      │      │   │
        │  ↓      ↓      ↓   │
        └──┼──────┼──────┼───┘
           │      │      │
           │      │      │
           │    [4.7kΩ]  │
           │      │      │
           ├──────┼──────┤
           │      │      │
          3.3V    │     GND
                  │
                  └──→ ESP32 GPIO 2
```

---

## 📋 Complete Wiring Checklist

### Power Connections
- [ ] ESP32 GND connected to power supply GND
- [ ] All relay modules GND connected together
- [ ] All sensor GND connected together
- [ ] Main GND rail connected to ESP32 GND
- [ ] 5V power supply positive to relay modules
- [ ] ESP32 3.3V output to temperature sensor VCC

### Hall Sensors (8 total)
- [ ] Hall Sensor 0 OUT → GPIO 4 (with pull-down)
- [ ] Hall Sensor 1 OUT → GPIO 5 (with pull-down)
- [ ] Hall Sensor 2 OUT → GPIO 12 (with pull-down)
- [ ] Hall Sensor 3 OUT → GPIO 13 (with pull-down)
- [ ] Hall Sensor 4 OUT → GPIO 14 (with pull-down)
- [ ] Hall Sensor 5 OUT → GPIO 15 (with pull-down)
- [ ] Hall Sensor 6 OUT → GPIO 16 (with pull-down)
- [ ] Hall Sensor 7 OUT → GPIO 17 (with pull-down)

### Motor Relays (10 total)
- [ ] Motor 0 relay IN → GPIO 18
- [ ] Motor 1 relay IN → GPIO 19
- [ ] Motor 2 relay IN → GPIO 21
- [ ] Motor 3 relay IN → GPIO 22
- [ ] Motor 4 relay IN → GPIO 23
- [ ] Motor 5 relay IN → GPIO 25
- [ ] Motor 6 relay IN → GPIO 26
- [ ] Motor 7 relay IN → GPIO 27
- [ ] Motor 8 relay IN → GPIO 32
- [ ] Motor 9 relay IN → GPIO 33

### Temperature Sensor
- [ ] DS18B20 VCC → 3.3V (with 4.7kΩ pull-up)
- [ ] DS18B20 DQ → GPIO 2
- [ ] DS18B20 GND → GND

### Power Supply
- [ ] 5V power supply positive → relay module VCC
- [ ] 5V power supply negative → common GND
- [ ] Supply can deliver minimum 3A current

---

## ⚡ Voltage Level Considerations

### ESP32 GPIO Voltage Levels
- **Input**: 0V (LOW) / 3.3V (HIGH)
- **Output**: 0V (LOW) / 3.3V (HIGH)
- **Maximum input voltage**: 3.3V (higher will damage GPIO)

### 5V Sensor Compatibility
If your Hall sensors output 5V:

**Option 1: Voltage Divider (Simple)**
```
5V Sensor Output
    │
   ┌─ R1 (4.7kΩ)
   │
   ├────→ ESP32 GPIO
   │
   │─ R2 (10kΩ to GND)
   │
  GND

Output voltage: 5V × (10k/(4.7k+10k)) ≈ 3.3V ✓
```

**Option 2: Logic Level Shifter (Recommended)**
- Use: TXS0108E or similar bidirectional level shifter
- Provides clean voltage conversion
- Protects GPIO pins from overvoltage

---

## 🔄 Signal Flow Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                    ESP32 LOOM CONTROLLER                        │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │ Hall     │  │ Hall     │  │ Hall     │  │ Hall     │        │
│  │ Sensors  │  │ Sensors  │  │ Sensors  │  │ Sensors  │        │
│  │ (0-3)    │  │ (4-7)    │  │          │  │          │        │
│  └────┬─────┘  └────┬─────┘  └──────────┘  └──────────┘        │
│       │             │                                            │
│       └─────[GPIO 4-17]──────────→ ┌──────────────────────┐    │
│                                     │  Read Sensor Input   │    │
│  ┌────────────────────────────┐     │                      │    │
│  │ Temperature Sensor DS18B20 │─────→ GPIO 2  (OneWire)    │    │
│  └────────────────────────────┘     │                      │    │
│                                     └──────────┬───────────┘    │
│  ┌──────────┐  ┌──────────┐                     │               │
│  │ Motor    │  │ Motor    │                     ↓               │
│  │ Relays   │  │ Relays   │        ┌─────────────────────┐    │
│  │ (0-4)    │  │ (5-9)    │        │   System State      │    │
│  └────┬─────┘  └────┬─────┘        │  (hallSensors[8])   │    │
│       │             │               │  (temperature)      │    │
│       └─────[GPIO 18-33]───────────→ │  (motors[10])      │    │
│                                     │                      │    │
│                                     └──────────┬───────────┘    │
│                                                │                │
│                    ┌──────────────────────────┘                │
│                    ↓                                             │
│        ┌────────────────────────┐                              │
│        │   REST API Server      │                              │
│        │   Port: 8080           │                              │
│        │                        │                              │
│        │ GET /api/status        │                              │
│        │ POST /api/motor/ctrl   │                              │
│        │ POST /api/loom/release │                              │
│        │ GET /api/history       │                              │
│        └────────┬───────────────┘                              │
│                 ↓                                               │
│        ┌────────────────────────┐                              │
│        │    WiFi Module         │                              │
│        │ (Built-in ESP32)       │                              │
│        │                        │                              │
│        │ SSID: Network          │                              │
│        │ Password: ******       │                              │
│        │ IP: 192.168.1.100      │                              │
│        └────────┬───────────────┘                              │
│                 │                                               │
│                 └──→ WiFi Router                               │
│                      │                                          │
│                      └──→ Flutter App on Phone/Computer        │
│                      └──→ Web Browser                          │
│                      └──→ Other Clients                        │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

---

## 🔌 ESP32 Pinout Reference

```
ESP32 Development Board Pinout:

┌─────────────────────────────────────────┐
│                                         │
│  GND GND  23  22  TX  RX  21   ─   ─   │
│  ─   3V3  19  18  5   17   4   2  15   │
│  ─   EN  GND GND  16  4   0  35  34    │
│  ─  BOOT  36  39  EN  ─   GND ─   ─   │
│                                         │
│    D1  D0   CLK  CMD  SD1  SD0  SD3   │
└─────────────────────────────────────────┘

Used Pins (in our sketch):
- INPUT:  GPIO 2, 4, 5, 12, 13, 14, 15, 16, 17
- OUTPUT: GPIO 18, 19, 21, 22, 23, 25, 26, 27, 32, 33
- POWER:  3.3V, 5V, GND
```

---

## 🧪 Testing Your Wiring

### Before Uploading Code

1. **Power Test**: Connect power only
   - Check if ESP32 LED lights up
   - Check if all relays have their LED on (if power indicators present)

2. **Continuity Test**: Using a multimeter
   - Test each GPIO pin has continuity to its connected component
   - Test all GND connections are properly connected

3. **Voltage Test**: Using a multimeter
   - Measure 5V supply = 5V (±0.2V)
   - Measure 3.3V supply = 3.3V (±0.1V)
   - Measure GPIO pins = should toggle 0V-3.3V during operation

### After Uploading Code

1. Open Serial Monitor (9600 baud)
2. Press ESP32 RESET button
3. Verify:
   - "Hall sensors configured" message
   - "Motor control pins configured" message
   - "Temperature sensor initialized" message
   - "WiFi connected" with IP address

4. Manually trigger hall sensors (magnet) → Check Serial output
5. Send motor control command → Check GPIO voltage with multimeter

---

## ⚠️ Common Mistakes

❌ **Mistake**: Connecting 5V sensor directly to 3.3V GPIO
✅ **Fix**: Use voltage divider or level shifter

❌ **Mistake**: Not using pull-up/pull-down resistors
✅ **Fix**: Always add 4.7kΩ resistor to signal lines

❌ **Mistake**: Not connecting all grounds together
✅ **Fix**: Create a common GND plane

❌ **Mistake**: Powering relays from ESP32 3.3V
✅ **Fix**: Use separate 5V power supply

❌ **Mistake**: Reversing VCC and GND connections
✅ **Fix**: Double-check before applying power (smoke = bad)

---

## 📊 Sample Circuit List

For a complete working system, you'll need:

```
Quantity | Component               | Part Number (Example)
---------|------------------------|------------------------
1        | ESP32 Dev Kit          | ESP32-DEVKIT-V1
8        | Hall Sensors (5V)      | US5881 or A3144
10       | Relay Modules (5V)     | SRD-05VDC-SL-C or equivalent
1        | Temperature Sensor     | DS18B20
1        | 5V Power Supply (3A)   | Any 5V 3A regulated supply
20       | 4.7kΩ Resistors        | Standard 1/4W
10       | 10kΩ Resistors         | Standard 1/4W
50       | Jumper Wires (assorted)| Dupont male-female
1        | USB Cable (Micro)      | For programming
1        | Breadboard or PCB      | For circuit building
```

---

**Next Step**: Follow [ESP32_SETUP_GUIDE.md](ESP32_SETUP_GUIDE.md) to upload the firmware!
