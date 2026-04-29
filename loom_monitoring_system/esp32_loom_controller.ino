#include <WiFi.h>
#include <WebServer.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// ================= WIFI =================
const char* SSID = "rupesh009";
const char* PASSWORD = "rupesh009";
WebServer server(8080);

// ================= LCD 20x4 I2C =================
// I2C address 0x27 or 0x3F (common for 20x4 LCD)
LiquidCrystal_I2C lcd(0x27, 20, 4);

// ================= PINS =================
// Hall Sensors (8 sensors for thread break detection)
const int HALL_SENSORS[8] = {4, 5, 12, 13, 14, 15, 16, 17};

// DHT11 Sensor
#define DHTPIN 2
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

// Buzzer (for alerts)
#define BUZZER_PIN 18

// Stepper Motor Pins (for loom movement control)
#define IN1 19  // Coil A+
#define IN2 21  // Coil A-
#define IN3 22  // Coil B+
#define IN4 23  // Coil B-

// ================= STATE =================
struct SystemState {
  bool hallSensors[8];
  float loomLength = 0;
  float temperature = 25;
  float humidity = 0;
  float totalLoomProduced = 0;
  int alertCount = 0;
  bool servoMotorActive = false;
};

SystemState systemState;

// ================= STEPPER =================
// 4-step full-step sequence for 28BYJ-48 stepper motor
int stepSequence[4][4] = {
  {1, 0, 0, 1},  // Step 1
  {1, 0, 0, 0},  // Step 2
  {1, 1, 0, 0},  // Step 3
  {0, 1, 0, 0}   // Step 4
};

int stepIndex = 0;
unsigned long lastStepTime = 0;
int stepsRemaining = 0;
bool motorRunning = false;

#define STEPS_PER_CM 50  // Calibration value (adjust based on your motor)
const int stepDelay = 3;  // Milliseconds between steps

// ================= TIMERS =================
unsigned long lastTempRead = 0;
unsigned long lastBuzz = 0;
unsigned long lastBackend = 0;
unsigned long lastLCDUpdate = 0;

// ================= FUNCTION DECLARATIONS =================
void testMotor();
void handleSerialCommand();
void readSensors();
void runStepper();
void handleBuzzer();
void updateLCD();
void sendDataToBackend();
void moveStepperByLength(float cm);
void setupRoutes();

// ================= SETUP =================
void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println("\n\n===== ESP32 LOOM MONITORING SYSTEM =====");
  Serial.println("Initializing hardware...\n");
  Serial.println("PIN CONFIGURATION:");
  Serial.println("Hall Sensors: 4,5,12,13,14,15,16,17");
  Serial.println("DHT11: GPIO2");
  Serial.println("Buzzer: GPIO18");
  Serial.println("Stepper: IN1=19, IN2=21, IN3=22, IN4=23");
  Serial.println("LCD 20x4 I2C: SDA=21, SCL=22");
  Serial.println("========================================\n");

  // Initialize Hall Sensors (INPUT_PULLUP for active LOW)
  for(int i = 0; i < 8; i++) {
    pinMode(HALL_SENSORS[i], INPUT_PULLUP);
  }

  // Initialize Buzzer
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);

  // Initialize Stepper Motor Pins
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);
  
  // Ensure motor is off at startup
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);

  // Initialize DHT Sensor
  dht.begin();
  
  // Initialize I2C LCD
  Wire.begin(21, 22);  // SDA=21, SCL=22 (ESP32 default I2C pins)
  lcd.init();
  lcd.backlight();
  lcd.clear();
  
  // Display startup message
  lcd.setCursor(2, 0);
  lcd.print("LOOM SYSTEM");
  lcd.setCursor(1, 1);
  lcd.print("Initializing...");
  lcd.setCursor(4, 2);
  lcd.print("Please wait");
  delay(2000);

  // Test stepper motor - brief test sequence
  Serial.println("Testing Stepper Motor...");
  testMotor();

  // Connect to WiFi
  Serial.print("Connecting to WiFi: ");
  Serial.println(SSID);
  WiFi.begin(SSID, PASSWORD);
  int wifiAttempts = 0;
  while(WiFi.status() != WL_CONNECTED && wifiAttempts < 20) {
    delay(500);
    Serial.print(".");
    wifiAttempts++;
  }

  if(WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✓ WiFi Connected");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
    
    // Display WiFi connected on LCD
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("WiFi: OK");
    lcd.setCursor(0, 1);
    lcd.print("IP:");
    lcd.print(WiFi.localIP());
    lcd.setCursor(0, 2);
    lcd.print("Ready!");
    delay(2000);
  } else {
    Serial.println("\n✗ WiFi Connection Failed");
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("WiFi: FAILED");
    lcd.setCursor(0, 1);
    lcd.print("Offline Mode");
    delay(2000);
  }

  Serial.println("\n===== Serial Commands =====");
  Serial.println("Type 'help' for available commands");
  Serial.println("test   - Test motor");
  Serial.println("status - Show system info");
  Serial.println("run N  - Run motor for N cm (e.g., run 5)");
  Serial.println("stop   - Stop motor");
  Serial.println("=============================\n");

  setupRoutes();
  server.begin();
  Serial.println("HTTP Server started on port 8080");
  
  // Clear LCD for main display
  lcd.clear();
}

// ================= LOOP =================
void loop() {
  server.handleClient();
  
  // Check for serial commands for debugging
  if(Serial.available()) {
    handleSerialCommand();
  }
  
  readSensors();
  runStepper();
  handleBuzzer();
  updateLCD();
  sendDataToBackend();
}

// ================= SENSOR =================
void readSensors() {
  // Read Hall sensors (LOW = active/break detected)
  for(int i = 0; i < 8; i++) {
    systemState.hallSensors[i] = (digitalRead(HALL_SENSORS[i]) == LOW);
  }

  // Read DHT11 temperature and humidity
  if(millis() - lastTempRead > 2000) {
    float t = dht.readTemperature();
    float h = dht.readHumidity();

    if(!isnan(t)) {
      systemState.temperature = t;
      systemState.humidity = h;

      if(t > 40) {
        systemState.alertCount++;
        Serial.print("⚠ High Temperature Alert: ");
        Serial.print(t);
        Serial.println("°C");
      }
    }

    lastTempRead = millis();
  }
}

// ================= STEPPER =================
void moveStepperByLength(float cm) {
  if(cm <= 0) {
    Serial.println("ERROR: Invalid length");
    return;
  }
  
  stepsRemaining = (int)(cm * STEPS_PER_CM);
  motorRunning = true;
  stepIndex = 0;
  lastStepTime = millis();
  
  Serial.print("Motor Command: ");
  Serial.print(cm);
  Serial.print(" cm = ");
  Serial.print(stepsRemaining);
  Serial.println(" steps");
}

void runStepper() {
  if(!motorRunning) return;

  if(millis() - lastStepTime > stepDelay) {
    lastStepTime = millis();

    // Set coil pattern for this step
    digitalWrite(IN1, stepSequence[stepIndex][0]);
    digitalWrite(IN2, stepSequence[stepIndex][1]);
    digitalWrite(IN3, stepSequence[stepIndex][2]);
    digitalWrite(IN4, stepSequence[stepIndex][3]);

    stepIndex++;
    if(stepIndex >= 4) stepIndex = 0;

    stepsRemaining--;

    if(stepsRemaining <= 0) {
      motorRunning = false;
      stepIndex = 0;

      // De-energize coils
      digitalWrite(IN1, LOW);
      digitalWrite(IN2, LOW);
      digitalWrite(IN3, LOW);
      digitalWrite(IN4, LOW);
      
      Serial.println("Motor: Stopped - Target length reached");
    }
  }
}

// ================= BUZZER =================
void handleBuzzer() {
  int activeSensors = 0;
  for(int i = 0; i < 8; i++) {
    if(systemState.hallSensors[i]) activeSensors++;
  }

  // Emergency: Any sensor active (thread break detected)
  if(activeSensors > 0) {
    digitalWrite(BUZZER_PIN, HIGH);  // Continuous beep
    return;
  }

  // High temperature alert - intermittent beep
  if(systemState.temperature > 40) {
    if(millis() - lastBuzz > 200) {
      lastBuzz = millis();
      digitalWrite(BUZZER_PIN, !digitalRead(BUZZER_PIN));
    }
  } 
  // Normal operation - short beep every 3 seconds
  else {
    if(millis() - lastBuzz > 3000) {
      lastBuzz = millis();
      digitalWrite(BUZZER_PIN, HIGH);
      delay(50);
      digitalWrite(BUZZER_PIN, LOW);
    }
  }
}

// ================= LCD 20x4 DISPLAY =================
void updateLCD() {
  if(millis() - lastLCDUpdate < 500) return;
  lastLCDUpdate = millis();

  // Row 0: Motor Status + WiFi Indicator
  lcd.setCursor(0, 0);
  if(motorRunning) {
    lcd.print("MOTOR:RUN        ");
  } else {
    lcd.print("MOTOR:READY      ");
  }
  
  // WiFi indicator in top right corner (position 19)
  lcd.setCursor(19, 0);
  if(WiFi.status() == WL_CONNECTED) {
    lcd.print("W");
  } else {
    lcd.print("N");
  }

  // Row 1: Temperature and Humidity
  lcd.setCursor(0, 1);
  lcd.print("T:");
  if(systemState.temperature < 10) lcd.print("0");
  lcd.print(systemState.temperature, 1);
  lcd.print("C  H:");
  if(systemState.humidity < 10) lcd.print("0");
  lcd.print(systemState.humidity, 0);
  lcd.print("%     ");

  // Row 2: Loom Length and Total Produced
  lcd.setCursor(0, 2);
  lcd.print("L:");
  if(systemState.loomLength < 10) lcd.print("0");
  lcd.print(systemState.loomLength, 1);
  lcd.print("cm T:");
  lcd.print(systemState.totalLoomProduced, 0);
  lcd.print("cm");

  // Row 3: Sensor Status (S1:on, S2:off, etc)
  lcd.setCursor(0, 3);
  lcd.print("S:");
  int charCount = 2;
  for(int i = 0; i < 8; i++) {
    if(i > 0) {
      lcd.print(",");
      charCount++;
    }
    
    // Sensor number
    lcd.print(i + 1);
    lcd.print(":");
    charCount += 2;
    
    // Sensor status
    if(systemState.hallSensors[i]) {
      lcd.print("on");
      charCount += 2;
    } else {
      lcd.print("of");
      charCount += 2;
    }
    
    // Stop if we're running out of space (20 chars max)
    if(charCount >= 19) break;
  }
  
  // Clear rest of line
  for(int i = charCount; i < 20; i++) {
    lcd.print(" ");
  }
}

// ================= MOTOR TEST =================
void testMotor() {
  Serial.println("Motor Test: Starting test sequence");
  
  // Update LCD
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Motor Testing...");
  lcd.setCursor(0, 1);
  lcd.print("Forward 20 steps");
  
  // Test forward direction
  Serial.print("Forward: ");
  for(int step = 0; step < 20; step++) {
    int idx = step % 4;
    digitalWrite(IN1, stepSequence[idx][0]);
    digitalWrite(IN2, stepSequence[idx][1]);
    digitalWrite(IN3, stepSequence[idx][2]);
    digitalWrite(IN4, stepSequence[idx][3]);
    delay(15);
    if(step % 5 == 0) Serial.print(".");
  }
  
  delay(200);
  
  lcd.setCursor(0, 2);
  lcd.print("Reverse 20 steps");
  
  // Test reverse direction
  Serial.print("\nReverse: ");
  for(int step = 20; step > 0; step--) {
    int idx = (step - 1) % 4;
    digitalWrite(IN1, stepSequence[idx][0]);
    digitalWrite(IN2, stepSequence[idx][1]);
    digitalWrite(IN3, stepSequence[idx][2]);
    digitalWrite(IN4, stepSequence[idx][3]);
    delay(15);
    if(step % 5 == 0) Serial.print(".");
  }
  
  // Stop motor
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
  
  Serial.println("\nMotor Test: Complete ✓");
  delay(1000);
}

// ================= SERIAL COMMAND HANDLER =================
void handleSerialCommand() {
  String command = Serial.readStringUntil('\n');
  command.trim();
  command.toLowerCase();

  if(command == "test") {
    Serial.println("Running motor test...");
    testMotor();
  } 
  else if(command == "status") {
    Serial.println("\n========== SYSTEM STATUS ==========");
    Serial.print("Temperature: ");
    Serial.print(systemState.temperature);
    Serial.println(" °C");
    Serial.print("Humidity: ");
    Serial.print(systemState.humidity);
    Serial.println(" %");
    Serial.print("Motor Running: ");
    Serial.println(motorRunning ? "YES" : "NO");
    Serial.print("Loom Length: ");
    Serial.print(systemState.loomLength);
    Serial.println(" cm");
    Serial.print("Total Produced: ");
    Serial.print(systemState.totalLoomProduced);
    Serial.println(" cm");
    Serial.print("WiFi Signal: ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
    Serial.print("Sensor Status: ");
    for(int i = 0; i < 8; i++) {
      Serial.print(systemState.hallSensors[i] ? "B" : ".");
      if(i < 7) Serial.print(",");
    }
    Serial.println();
    Serial.println("===================================");
  }
  else if(command.startsWith("run")) {
    int spaceIndex = command.indexOf(' ');
    if(spaceIndex > 0) {
      float length = command.substring(spaceIndex + 1).toFloat();
      if(length > 0) {
        Serial.print("Starting motor: ");
        Serial.print(length);
        Serial.println(" cm");
        moveStepperByLength(length);
      } else {
        Serial.println("Error: Invalid length");
      }
    } else {
      Serial.println("Usage: run <length_cm>");
    }
  }
  else if(command == "stop") {
    motorRunning = false;
    stepsRemaining = 0;
    digitalWrite(IN1, LOW);
    digitalWrite(IN2, LOW);
    digitalWrite(IN3, LOW);
    digitalWrite(IN4, LOW);
    Serial.println("Motor stopped");
  }
  else if(command == "reset") {
    systemState.loomLength = 0;
    systemState.totalLoomProduced = 0;
    systemState.alertCount = 0;
    Serial.println("System counters reset");
  }
  else if(command == "help") {
    Serial.println("\n========== COMMANDS ==========");
    Serial.println("test         - Run motor test sequence");
    Serial.println("status       - Show system status");
    Serial.println("run N        - Run motor for N cm (e.g., run 5)");
    Serial.println("stop         - Stop motor");
    Serial.println("reset        - Reset counters");
    Serial.println("help         - Show this help menu");
    Serial.println("===============================");
  }
  else if(command.length() > 0) {
    Serial.print("Unknown command: ");
    Serial.println(command);
    Serial.println("Type 'help' for available commands");
  }
}

// ================= BACKEND =================
void sendDataToBackend() {
  if(WiFi.status() != WL_CONNECTED) return;

  if(millis() - lastBackend < 5000) return;
  lastBackend = millis();

  // Update servo motor status based on stepper running
  systemState.servoMotorActive = motorRunning;

  // Create JSON document with all sensor data
  StaticJsonDocument<512> doc;
  
  // Temperature and humidity data
  doc["temp"] = systemState.temperature;
  doc["humidity"] = systemState.humidity;
  
  // Motor status
  doc["servoMotor"]["active"] = systemState.servoMotorActive;
  doc["servoMotor"]["running"] = motorRunning;
  doc["servoMotor"]["stepsRemaining"] = stepsRemaining;
  
  // Sensor pack - 8 sensors with status
  JsonArray sensorPack = doc.createNestedArray("sensorPack");
  for(int i = 0; i < 8; i++) {
    JsonObject sensor = sensorPack.createNestedObject();
    sensor["id"] = i;
    sensor["status"] = systemState.hallSensors[i] ? "break" : "normal";
    sensor["active"] = systemState.hallSensors[i];
  }
  
  // Additional system info
  doc["loomLength"] = systemState.loomLength;
  doc["totalLoomProduced"] = systemState.totalLoomProduced;
  doc["alertCount"] = systemState.alertCount;
  doc["timestamp"] = millis();
  doc["wifiSignal"] = WiFi.RSSI();

  String json;
  serializeJson(doc, json);

  // Print to Serial Monitor for debugging
  Serial.println("\n========== SENSOR DATA ==========");
  Serial.print("Temp: ");
  Serial.print(systemState.temperature);
  Serial.println("°C");
  Serial.print("Humidity: ");
  Serial.print(systemState.humidity);
  Serial.println("%");
  Serial.print("Motor: ");
  Serial.println(motorRunning ? "RUNNING" : "STOPPED");
  Serial.print("Loom Length: ");
  Serial.print(systemState.loomLength);
  Serial.println("cm");
  Serial.print("Total Produced: ");
  Serial.print(systemState.totalLoomProduced);
  Serial.println("cm");
  Serial.println("Sensor Pack:");
  for(int i = 0; i < 8; i++) {
    Serial.print("  Sensor ");
    Serial.print(i);
    Serial.print(": ");
    Serial.println(systemState.hallSensors[i] ? "BREAK" : "OK");
  }
  Serial.println("==================================\n");

  // Send to backend
  HTTPClient http;
  http.begin("http://10.240.67.14:3000/api/esp32/sensor-data");
  http.addHeader("Content-Type", "application/json");

  int code = http.POST(json);
  Serial.print("Backend Response Code: ");
  Serial.println(code);
  if(code == 200) {
    String response = http.getString();
    Serial.print("Response: ");
    Serial.println(response);
  } else {
    Serial.println("✗ Failed to send data");
  }

  http.end();
}

// ================= API ROUTES =================
void setupRoutes() {
  // Get system status
  server.on("/api/status", HTTP_GET, [](){
    StaticJsonDocument<256> doc;
    doc["temp"] = systemState.temperature;
    doc["hum"] = systemState.humidity;
    doc["loom"] = systemState.loomLength;
    doc["total"] = systemState.totalLoomProduced;
    doc["motorRunning"] = motorRunning;
    doc["wifiSignal"] = WiFi.RSSI();
    doc["uptime"] = millis() / 1000;

    String res;
    serializeJson(doc, res);
    server.send(200, "application/json", res);
  });

  // Release loom length
  server.on("/api/loom/release", HTTP_POST, [](){
    StaticJsonDocument<200> doc;
    deserializeJson(doc, server.arg("plain"));

    float cm = doc["lengthCm"];

    if(cm > 0 && cm <= 1000) {
      moveStepperByLength(cm);
      systemState.loomLength += cm;
      systemState.totalLoomProduced += cm;
      
      String response = "{\"success\":true,\"status\":\"Motor started\",\"length\":" + String(cm) + "}";
      server.send(200, "application/json", response);
    } else {
      server.send(400, "application/json", "{\"success\":false,\"error\":\"Invalid length (must be 1-1000cm)\"}");
    }
  });

  // Test motor endpoint
  server.on("/api/motor/test", HTTP_POST, [](){
    testMotor();
    server.send(200, "application/json", "{\"success\":true,\"message\":\"Motor test executed\"}");
  });

  // Debug endpoint to check system status
  server.on("/api/debug/status", HTTP_GET, [](){
    StaticJsonDocument<512> doc;
    doc["motorRunning"] = motorRunning;
    doc["stepsRemaining"] = stepsRemaining;
    doc["temp"] = systemState.temperature;
    doc["humidity"] = systemState.humidity;
    doc["wifiSignal"] = WiFi.RSSI();
    doc["uptime"] = millis();
    
    JsonArray sensors = doc.createNestedArray("hallSensors");
    for(int i = 0; i < 8; i++) {
      sensors.add(systemState.hallSensors[i]);
    }

    String res;
    serializeJson(doc, res);
    server.send(200, "application/json", res);
  });

  // Stop motor endpoint
  server.on("/api/motor/stop", HTTP_POST, [](){
    motorRunning = false;
    stepsRemaining = 0;
    digitalWrite(IN1, LOW);
    digitalWrite(IN2, LOW);
    digitalWrite(IN3, LOW);
    digitalWrite(IN4, LOW);
    
    server.send(200, "application/json", "{\"success\":true,\"message\":\"Motor stopped\"}");
  });

  // Get sensor array status
  server.on("/api/sensors", HTTP_GET, [](){
    StaticJsonDocument<256> doc;
    JsonArray sensors = doc.createNestedArray("sensors");
    for(int i = 0; i < 8; i++) {
      JsonObject sensor = sensors.createNestedObject();
      sensor["id"] = i + 1;
      sensor["status"] = systemState.hallSensors[i] ? "break" : "normal";
    }
    doc["timestamp"] = millis();
    
    String res;
    serializeJson(doc, res);
    server.send(200, "application/json", res);
  });

  // Reset system counters
  server.on("/api/reset", HTTP_POST, [](){
    systemState.loomLength = 0;
    systemState.alertCount = 0;
    server.send(200, "application/json", "{\"success\":true,\"message\":\"Counters reset\"}");
  });
}