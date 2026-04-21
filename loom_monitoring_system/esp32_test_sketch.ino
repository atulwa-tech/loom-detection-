/**
 * ESP32 LOOM CONTROLLER - SIMPLE TEST SKETCH
 * 
 * Use this to test your hardware before running the full firmware
 * This is much simpler and helps debug hardware issues
 */

#include <OneWire.h>
#include <DallasTemperature.h>

// Pin Definitions
const int HALL_SENSORS[8] = {4, 5, 12, 13, 14, 15, 16, 17};
const int MOTOR_PINS[10] = {18, 19, 21, 22, 23, 25, 26, 27, 32, 33};
const int TEMP_SENSOR_PIN = 2;

// Temperature Sensor Setup
OneWire oneWire(TEMP_SENSOR_PIN);
DallasTemperature tempSensor(&oneWire);

// Test configuration
int testMode = 0;  // 0=idle, 1=Hall sensors, 2=Motors, 3=Temperature

void setup() {
  Serial.begin(115200);
  delay(2000);
  
  Serial.println("\n\n=== ESP32 LOOM CONTROLLER - HARDWARE TEST ===\n");
  
  // Initialize Hall sensor pins
  for (int i = 0; i < 8; i++) {
    pinMode(HALL_SENSORS[i], INPUT);
  }
  Serial.println("✓ Hall sensors initialized");
  
  // Initialize motor pins
  for (int i = 0; i < 10; i++) {
    pinMode(MOTOR_PINS[i], OUTPUT);
    digitalWrite(MOTOR_PINS[i], LOW);
  }
  Serial.println("✓ Motor pins initialized\n");
  
  // Initialize temperature sensor
  tempSensor.begin();
  Serial.println("✓ Temperature sensor initialized\n");
  
  // Print menu
  printMenu();
}

void loop() {
  // Check for serial input
  if (Serial.available()) {
    char input = Serial.read();
    handleInput(input);
  }
  
  // Run active test
  if (testMode == 1) {
    testHallSensors();
  } else if (testMode == 2) {
    testMotors();
  } else if (testMode == 3) {
    testTemperature();
  }
  
  delay(500);
}

// ========== MENU ==========
void printMenu() {
  Serial.println("\n╔════════════════════════════════════╗");
  Serial.println("║     HARDWARE TEST MENU              ║");
  Serial.println("╠════════════════════════════════════╣");
  Serial.println("║  1 = Test Hall Sensors (0-7)       ║");
  Serial.println("║  2 = Test Motors (0-9)             ║");
  Serial.println("║  3 = Test Temperature Sensor       ║");
  Serial.println("║  4 = Stop Current Test             ║");
  Serial.println("║  5 = Pinout Information            ║");
  Serial.println("║  6 = System Diagnostics            ║");
  Serial.println("║  ? = Show This Menu                ║");
  Serial.println("╚════════════════════════════════════╝\n");
}

void handleInput(char input) {
  switch(input) {
    case '1':
      testMode = 1;
      Serial.println("\n▶ Starting Hall Sensor Test");
      Serial.println("Place a magnet near each sensor and observe the output below:");
      Serial.println("Sensor │ Status");
      Serial.println("───────┼────────\n");
      break;
      
    case '2':
      testMode = 2;
      Serial.println("\n▶ Starting Motor Test");
      Serial.println("Motors will turn ON for 1 second, then OFF\n");
      break;
      
    case '3':
      testMode = 3;
      Serial.println("\n▶ Starting Temperature Sensor Test");
      Serial.println("Reading temperature every 1 second...\n");
      break;
      
    case '4':
      testMode = 0;
      allMotorsOff();
      Serial.println("\n⚫ Test stopped\n");
      printMenu();
      break;
      
    case '5':
      printPinout();
      break;
      
    case '6':
      printDiagnostics();
      break;
      
    case '?':
      printMenu();
      break;
      
    default:
      if (input == '\n' || input == '\r') return;
      Serial.print("Unknown command: ");
      Serial.println(input);
      Serial.println("Press '?' for menu\n");
  }
}

// ========== TEST FUNCTIONS ==========

void testHallSensors() {
  static unsigned long lastPrint = 0;
  
  if (millis() - lastPrint < 500) return;  // Update every 500ms
  lastPrint = millis();
  
  Serial.println("Sensor │ GPIO │ Status");
  Serial.println("───────┼──────┼────────");
  
  for (int i = 0; i < 8; i++) {
    bool state = digitalRead(HALL_SENSORS[i]);
    Serial.print("  ");
    Serial.print(i);
    Serial.print("    │ ");
    Serial.print(HALL_SENSORS[i]);
    Serial.print("   │ ");
    Serial.println(state ? "TRIGGERED ✓" : "WAITING");
  }
  Serial.println();
}

void testMotors() {
  static unsigned long testStart = 0;
  static int currentMotor = 0;
  static bool motorOn = true;
  
  // Initialize test
  if (testStart == 0) {
    testStart = millis();
    digitalWrite(MOTOR_PINS[0], HIGH);
    Serial.print("Testing Motor 0...");
    return;
  }
  
  unsigned long elapsed = millis() - testStart;
  
  // Switch motor every 1 second
  if (elapsed > 1000) {
    // Turn off current motor
    digitalWrite(MOTOR_PINS[currentMotor], LOW);
    Serial.println(" OFF");
    
    // Move to next motor
    currentMotor++;
    testStart = millis();
    
    if (currentMotor >= 10) {
      // Test complete
      testMode = 0;
      Serial.println("\n✓ Motor test complete!");
      Serial.println("All motors should have been activated in sequence\n");
      printMenu();
      return;
    }
    
    // Turn on next motor
    digitalWrite(MOTOR_PINS[currentMotor], HIGH);
    Serial.print("Testing Motor ");
    Serial.print(currentMotor);
    Serial.print("...");
  }
}

void testTemperature() {
  static unsigned long lastRead = 0;
  
  if (millis() - lastRead < 1000) return;  // Update every 1 second
  lastRead = millis();
  
  tempSensor.requestTemperatures();
  float temp = tempSensor.getTempCByIndex(0);
  
  Serial.print("Temperature: ");
  
  if (temp > -127 && temp < 85) {
    Serial.print(temp);
    Serial.println(" °C ✓");
  } else {
    Serial.print(temp);
    Serial.println(" °C ✗ ERROR - Check wiring!");
  }
}

// ========== UTILITY FUNCTIONS ==========

void allMotorsOff() {
  for (int i = 0; i < 10; i++) {
    digitalWrite(MOTOR_PINS[i], LOW);
  }
}

void printPinout() {
  Serial.println("\n╔════════════════════════════════════╗");
  Serial.println("║         PIN CONFIGURATION           ║");
  Serial.println("╠════════════════════════════════════╣");
  Serial.println("║ HALL SENSORS (INPUT)                ║");
  Serial.println("║ ─────────────────────────────────── ║");
  for (int i = 0; i < 8; i++) {
    Serial.print("║ Sensor ");
    Serial.print(i);
    Serial.print(": GPIO ");
    Serial.print(HALL_SENSORS[i]);
    Serial.println("                         ║");
  }
  
  Serial.println("║                                     ║");
  Serial.println("║ MOTOR RELAYS (OUTPUT)               ║");
  Serial.println("║ ─────────────────────────────────── ║");
  for (int i = 0; i < 10; i++) {
    Serial.print("║ Motor ");
    if (i < 10) Serial.print(" ");  // Padding for single digits
    Serial.print(i);
    Serial.print(": GPIO ");
    if (MOTOR_PINS[i] < 10) Serial.print(" ");  // Padding
    Serial.print(MOTOR_PINS[i]);
    Serial.println("                         ║");
  }
  
  Serial.println("║                                     ║");
  Serial.println("║ TEMPERATURE SENSOR                  ║");
  Serial.println("║ ─────────────────────────────────── ║");
  Serial.print("║ DS18B20: GPIO ");
  Serial.print(TEMP_SENSOR_PIN);
  Serial.println("                            ║");
  
  Serial.println("╚════════════════════════════════════╝\n");
}

void printDiagnostics() {
  Serial.println("\n╔════════════════════════════════════╗");
  Serial.println("║         SYSTEM DIAGNOSTICS          ║");
  Serial.println("╠════════════════════════════════════╣");
  
  // Check Hall sensors
  Serial.println("║ HALL SENSORS STATUS:                ║");
  int activeHallSensors = 0;
  for (int i = 0; i < 8; i++) {
    if (digitalRead(HALL_SENSORS[i]) == HIGH) {
      activeHallSensors++;
    }
  }
  Serial.print("║  ");
  Serial.print(activeHallSensors);
  Serial.println("/8 sensors triggered                  ║");
  
  // Check Motor pins
  Serial.println("║                                     ║");
  Serial.println("║ MOTOR PINS STATUS:                  ║");
  int activeMotors = 0;
  for (int i = 0; i < 10; i++) {
    // Note: This reads what we last set, not the actual relay state
    if (digitalRead(MOTOR_PINS[i]) == HIGH) {
      activeMotors++;
    }
  }
  Serial.print("║  ");
  Serial.print(activeMotors);
  Serial.println("/10 motors currently ON              ║");
  
  // Check Temperature sensor
  Serial.println("║                                     ║");
  Serial.println("║ TEMPERATURE SENSOR:                 ║");
  tempSensor.requestTemperatures();
  float temp = tempSensor.getTempCByIndex(0);
  
  if (temp > -127 && temp < 85) {
    Serial.print("║  Status: OK - ");
    Serial.print(temp);
    Serial.println(" °C                 ║");
  } else {
    Serial.print("║  Status: ERROR - ");
    Serial.print(temp);
    Serial.println(" (Check wiring)       ║");
  }
  
  // Uptime
  Serial.println("║                                     ║");
  Serial.println("║ SYSTEM INFO:                        ║");
  Serial.print("║  Uptime: ");
  Serial.print(millis() / 1000);
  Serial.println(" seconds                      ║");
  
  Serial.print("║  Free Heap: ");
  Serial.print(ESP.getFreeHeap());
  Serial.println(" bytes                 ║");
  
  Serial.println("╚════════════════════════════════════╝\n");
}

// ========== END OF TEST SKETCH ==========

/*
USAGE INSTRUCTIONS:

1. Upload this sketch to your ESP32 using Arduino IDE
2. Open Serial Monitor (Tools → Serial Monitor)
3. Set baud rate to 115200
4. Press ESP32 RESET button
5. Follow the on-screen menu to test each component

TEST PROCEDURES:

TEST 1 - Hall Sensors:
  - Select option "1"
  - Take a magnet and bring it near each sensor
  - You should see the status change from "WAITING" to "TRIGGERED"
  - If all 8 sensors show "TRIGGERED" when magnet is applied, they work!

TEST 2 - Motors:
  - Select option "2"
  - Listen for relay clicks as each motor turns on for 1 second
  - If you have LEDs on the relay, they should light up
  - You should see 10 sequential clicks/activations

TEST 3 - Temperature Sensor:
  - Select option "3"
  - Temperature should update every second
  - It should read roughly room temperature (20-25°C)
  - Try warming the sensor with your finger
  - The reading should increase slightly

DIAGNOSTICS:
  - Select option "6" anytime to see system status
  - Shows how many sensors are active
  - Shows which motors are on
  - Shows temperature reading
  - Shows memory usage

TROUBLESHOOTING:

Hall Sensor not working?
  ✓ Check GPIO pin connection
  ✓ Verify 5V power to sensor
  ✓ Test with voltage multimeter
  ✓ Try different GPIO pin

Motor not responding?
  ✓ Check relay connections
  ✓ Verify 5V power to relay
  ✓ Test relay with direct 5V (should click)
  ✓ Use multimeter to check GPIO voltage changes from 0V to 3.3V

Temperature sensor not working?
  ✓ Check OneWire library installed
  ✓ Verify GPIO 2 connection
  ✓ Check 4.7kΩ pull-up resistor
  ✓ Test with DS18B20 example sketch from library

WiFi issues (next step):
  - This sketch doesn't test WiFi
  - Use the full firmware (esp32_loom_controller.ino) for WiFi testing
  - Check your SSID and PASSWORD in the main firmware
*/
