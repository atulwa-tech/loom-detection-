/**
 * ESP32 LOOM MONITORING SYSTEM - ARDUINO SKETCH
 * Complete working firmware for industrial loom control
 * 
 * Hardware Requirements:
 * - ESP32 Development Board
 * - 8x Hall Sensors (GPIO pins 4, 5, 12, 13, 14, 15, 16, 17)
 * - 10x Motor Control Relays (GPIO pins 18, 19, 21, 22, 23, 25, 26, 27, 32, 33)
 * - 1x Temperature Sensor DS18B20 or DHT22 (GPIO 2)
 * - 5V Power Supply
 * 
 * WiFi Configuration:
 * - SSID: Your WiFi network name
 * - PASSWORD: Your WiFi password
 * - IP will be printed to serial monitor
 */

#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <time.h>

// ===================== CONFIGURATION =====================
const char* SSID = "YOUR_WIFI_SSID";
const char* PASSWORD = "YOUR_WIFI_PASSWORD";
const int PORT = 8080;

// Pin Definitions
const int HALL_SENSORS[8] = {4, 5, 12, 13, 14, 15, 16, 17};
const int MOTOR_PINS[10] = {18, 19, 21, 22, 23, 25, 26, 27, 32, 33};
const int TEMP_SENSOR_PIN = 2;

// Temperature Sensor Setup
OneWire oneWire(TEMP_SENSOR_PIN);
DallasTemperature tempSensor(&oneWire);

// Web Server
WebServer server(PORT);

// ===================== SYSTEM STATE =====================
struct SystemState {
  bool hallSensors[8] = {false};
  float loomLength = 0.0;
  float temperature = 25.0;
  bool motors[10] = {false};
  bool isConnected = true;
  float totalLoomProduced = 0.0;
  unsigned long lastUpdated = 0;
  unsigned long startTime = 0;
  float temperatureSum = 0.0;
  int temperatureSamples = 0;
  int alertCount = 0;
};

SystemState systemState;
unsigned long lastTempRead = 0;
const unsigned long TEMP_READ_INTERVAL = 5000; // 5 seconds

// ===================== SETUP =====================
void setup() {
  Serial.begin(115200);
  delay(2000);
  
  Serial.println("\n\n");
  Serial.println("=======================================");
  Serial.println("ESP32 LOOM MONITORING SYSTEM");
  Serial.println("=======================================");
  
  // Initialize GPIO pins
  initializePins();
  
  // Initialize temperature sensor
  tempSensor.begin();
  Serial.println("✓ Temperature sensor initialized");
  
  // Connect to WiFi
  connectToWiFi();
  
  // Initialize system time
  systemState.startTime = millis();
  systemState.lastUpdated = millis();
  
  // Setup routes
  setupRoutes();
  
  // Start web server
  server.begin();
  Serial.println("✓ Web server started on port " + String(PORT));
  Serial.println("=======================================\n");
}

// ===================== MAIN LOOP =====================
void loop() {
  // Handle incoming HTTP requests
  server.handleClient();
  
  // Read sensors periodically
  readSensors();
  
  // Update system state
  systemState.lastUpdated = millis();
}

// ===================== PIN INITIALIZATION =====================
void initializePins() {
  // Configure Hall sensor pins as inputs
  for (int i = 0; i < 8; i++) {
    pinMode(HALL_SENSORS[i], INPUT);
  }
  Serial.println("✓ Hall sensors configured");
  
  // Configure motor pins as outputs
  for (int i = 0; i < 10; i++) {
    pinMode(MOTOR_PINS[i], OUTPUT);
    digitalWrite(MOTOR_PINS[i], LOW);
  }
  Serial.println("✓ Motor control pins configured");
}

// ===================== WiFi CONNECTION =====================
void connectToWiFi() {
  Serial.print("Connecting to WiFi: ");
  Serial.println(SSID);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(SSID, PASSWORD);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✓ WiFi connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
    Serial.print("Local Port: ");
    Serial.println(PORT);
  } else {
    Serial.println("\n✗ WiFi connection failed!");
    Serial.println("Please check SSID and PASSWORD");
  }
}

// ===================== SENSOR READING =====================
void readSensors() {
  // Read Hall sensors
  for (int i = 0; i < 8; i++) {
    systemState.hallSensors[i] = digitalRead(HALL_SENSORS[i]) == HIGH;
  }
  
  // Read temperature sensor periodically
  if (millis() - lastTempRead >= TEMP_READ_INTERVAL) {
    tempSensor.requestTemperatures();
    float temp = tempSensor.getTempCByIndex(0);
    
    // Validate temperature reading
    if (temp > -127 && temp < 85) {
      systemState.temperature = temp;
      systemState.temperatureSum += temp;
      systemState.temperatureSamples++;
      
      // Alert if temperature too high
      if (temp > 40.0) {
        systemState.alertCount++;
        Serial.print("⚠ High temperature alert: ");
        Serial.println(temp);
      }
    }
    
    lastTempRead = millis();
  }
}

// ===================== API ROUTES =====================
void setupRoutes() {
  // GET /api/status - Fetch current system status
  server.on("/api/status", HTTP_GET, handleGetStatus);
  
  // POST /api/motor/control - Control a motor
  server.on("/api/motor/control", HTTP_POST, handleMotorControl);
  
  // POST /api/loom/release - Release loom for specified length
  server.on("/api/loom/release", HTTP_POST, handleLoomRelease);
  
  // GET /api/history - Get system history
  server.on("/api/history", HTTP_GET, handleGetHistory);
  
  // GET /health - Health check
  server.on("/health", HTTP_GET, handleHealth);
  
  // 404 handler
  server.onNotFound(handleNotFound);
}

// ===================== HANDLERS =====================

/**
 * GET /api/status
 * Returns current system status
 */
void handleGetStatus() {
  StaticJsonDocument<1024> doc;
  
  // Hall sensors array
  JsonArray hallArray = doc.createNestedArray("hallSensors");
  for (int i = 0; i < 8; i++) {
    hallArray.add(systemState.hallSensors[i]);
  }
  
  // System data
  doc["loomLength"] = serialized(String(systemState.loomLength, 1));
  doc["temperature"] = serialized(String(systemState.temperature, 1));
  
  // Motors array
  JsonArray motorsArray = doc.createNestedArray("motors");
  for (int i = 0; i < 10; i++) {
    motorsArray.add(systemState.motors[i]);
  }
  
  doc["isConnected"] = systemState.isConnected;
  doc["totalLoomProduced"] = serialized(String(systemState.totalLoomProduced, 1));
  doc["lastUpdated"] = getISOTimestamp();
  
  // Send response
  String response;
  serializeJson(doc, response);
  server.sendHeader("Content-Type", "application/json");
  server.send(200, "application/json", response);
  
  Serial.println("→ GET /api/status");
}

/**
 * POST /api/motor/control
 * Control a single motor
 * Request: {"motorId": 0, "state": true}
 */
void handleMotorControl() {
  if (!server.hasArg("plain")) {
    server.send(400, "application/json", "{\"error\": \"No request body\"}");
    return;
  }
  
  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, server.arg("plain"));
  
  if (error) {
    server.send(400, "application/json", "{\"error\": \"Invalid JSON\"}");
    return;
  }
  
  int motorId = doc["motorId"];
  bool state = doc["state"];
  
  // Validate motor ID
  if (motorId < 0 || motorId >= 10) {
    server.send(400, "application/json", "{\"error\": \"Invalid motorId\"}");
    return;
  }
  
  // Control motor
  digitalWrite(MOTOR_PINS[motorId], state ? HIGH : LOW);
  systemState.motors[motorId] = state;
  
  Serial.print("→ POST /api/motor/control - Motor ");
  Serial.print(motorId);
  Serial.println(state ? " ON" : " OFF");
  
  // Send success response
  server.send(200, "application/json", "{\"success\": true}");
}

/**
 * POST /api/loom/release
 * Release loom fabric for specified length
 * Request: {"lengthCm": 4.0}
 */
void handleLoomRelease() {
  if (!server.hasArg("plain")) {
    server.send(400, "application/json", "{\"error\": \"No request body\"}");
    return;
  }
  
  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, server.arg("plain"));
  
  if (error) {
    server.send(400, "application/json", "{\"error\": \"Invalid JSON\"}");
    return;
  }
  
  float lengthCm = doc["lengthCm"];
  
  // Validate length
  if (lengthCm <= 0 || lengthCm > 50) {
    server.send(400, "application/json", "{\"error\": \"Invalid length\"}");
    return;
  }
  
  // Simulate loom release
  // In a real system, this would trigger a motor or stepper
  systemState.loomLength += lengthCm;
  systemState.totalLoomProduced += lengthCm;
  
  Serial.print("→ POST /api/loom/release - Released ");
  Serial.print(lengthCm);
  Serial.println(" cm");
  
  // Send success response
  server.send(200, "application/json", "{\"success\": true}");
}

/**
 * GET /api/history
 * Returns system history and statistics
 */
void handleGetHistory() {
  StaticJsonDocument<512> doc;
  
  unsigned long uptime = (millis() - systemState.startTime) / 1000;
  float averageTemp = systemState.temperatureSamples > 0 
    ? systemState.temperatureSum / systemState.temperatureSamples 
    : 0;
  
  doc["totalProduced"] = serialized(String(systemState.totalLoomProduced, 1));
  doc["uptime"] = uptime;
  doc["averageTemperature"] = serialized(String(averageTemp, 1));
  doc["alertCount"] = systemState.alertCount;
  
  String response;
  serializeJson(doc, response);
  server.sendHeader("Content-Type", "application/json");
  server.send(200, "application/json", response);
  
  Serial.println("→ GET /api/history");
}

/**
 * GET /health
 * Health check endpoint
 */
void handleHealth() {
  StaticJsonDocument<256> doc;
  doc["status"] = "ok";
  doc["uptime"] = (millis() - systemState.startTime) / 1000;
  doc["wifi"] = WiFi.status() == WL_CONNECTED ? "connected" : "disconnected";
  doc["ip"] = WiFi.localIP().toString();
  
  String response;
  serializeJson(doc, response);
  server.sendHeader("Content-Type", "application/json");
  server.send(200, "application/json", response);
}

/**
 * Handle 404 errors
 */
void handleNotFound() {
  StaticJsonDocument<256> doc;
  doc["error"] = "Not found";
  doc["path"] = server.uri();
  
  String response;
  serializeJson(doc, response);
  server.send(404, "application/json", response);
}

// ===================== UTILITY FUNCTIONS =====================

/**
 * Get current time in ISO 8601 format
 */
String getISOTimestamp() {
  time_t now = time(nullptr);
  struct tm* timeinfo = localtime(&now);
  char buffer[25];
  strftime(buffer, sizeof(buffer), "%Y-%m-%dT%H:%M:%S.000Z", timeinfo);
  return String(buffer);
}

/**
 * Print system status to serial monitor
 */
void printSystemStatus() {
  Serial.println("\n=== SYSTEM STATUS ===");
  Serial.print("Temperature: ");
  Serial.print(systemState.temperature);
  Serial.println(" °C");
  
  Serial.print("Loom Length: ");
  Serial.print(systemState.loomLength);
  Serial.println(" cm");
  
  Serial.print("Total Produced: ");
  Serial.print(systemState.totalLoomProduced);
  Serial.println(" cm");
  
  Serial.print("Motors: ");
  int activeMotors = 0;
  for (int i = 0; i < 10; i++) {
    if (systemState.motors[i]) activeMotors++;
  }
  Serial.print(activeMotors);
  Serial.println(" active");
  
  Serial.print("Hall Sensors: ");
  int activeSensors = 0;
  for (int i = 0; i < 8; i++) {
    if (systemState.hallSensors[i]) activeSensors++;
  }
  Serial.print(activeSensors);
  Serial.println(" triggered");
  Serial.println("====================\n");
}

// ===================== ADVANCED FEATURES =====================

/**
 * Optional: Add this to loop() to periodically print status
 * if (millis() % 30000 == 0) printSystemStatus();
 */

/**
 * Optional: WebSocket support (requires AsyncWebServer)
 * For real-time data streaming, see advanced implementation below
 */

/*
// ADVANCED: WebSocket Server Setup
#include <AsyncWebServer.h>
#include <AsyncWebsocket.h>

AsyncWebServer wsServer(8080);

void onWsEvent(AsyncWebSocket * server, AsyncWebSocketClient * client, AwsEventType type, void * arg, uint8_t *data, size_t len) {
  if(type == WS_EVT_CONNECT){
    Serial.println("WebSocket client connected");
  } else if(type == WS_EVT_DISCONNECT){
    Serial.println("WebSocket client disconnected");
  } else if(type == WS_EVT_DATA){
    // Handle incoming WebSocket data
    StaticJsonDocument<256> doc;
    deserializeJson(doc, data);
    // Process command
  }
}

// In setup():
// AsyncWebSocket ws("/ws");
// wsServer.addHandler(&ws);
// ws.onEvent(onWsEvent);
// wsServer.begin();

// Broadcast sensor data periodically:
void broadcastSensorData() {
  StaticJsonDocument<512> doc;
  
  JsonArray hallArray = doc.createNestedArray("hallSensors");
  for (int i = 0; i < 8; i++) {
    hallArray.add(systemState.hallSensors[i]);
  }
  
  doc["temperature"] = systemState.temperature;
  doc["loomLength"] = systemState.loomLength;
  
  String msg;
  serializeJson(doc, msg);
  ws.textAll(msg);
}
*/

// ===================== END OF SKETCH =====================
