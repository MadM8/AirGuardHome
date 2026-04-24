#include <Arduino.h>
#include <Wire.h>
#include <DHT.h>
#include <WiFi.h>
<<<<<<< HEAD
#include <Wire.h>
=======
#include <Adafruit_PM25AQI.h>
#include <Adafruit_SGP30.h>
>>>>>>> bdb0da68d4b6340f3019eda9f04aa0022b85c78c
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include "Adafruit_SGP30.h"

// ── Pin Config ────────────────────────────────────────────
#define DHTPIN   4
#define DHTTYPE  DHT22

// ── WiFi Credentials ──────────────────────────────────────
#define WIFI_SSID     "iPhone 4s"
#define WIFI_PASSWORD "GusPirate"

// ── Firebase Credentials ──────────────────────────────────
#define API_KEY      "AIzaSyANUJRVCvBLFiWtJSqP6NS7wVZuSINySik"
#define DATABASE_URL "https://airguardfire-default-rtdb.firebaseio.com/"

<<<<<<< HEAD
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
DHT dht(DHTPIN, DHTTYPE);
Adafruit_SGP30 sgp;

//function definition 
uint32_t getAbsoluteHumidity(float temperature, float humidity) {
  // Implementation for calculating absolute humidity
  const float absoluteHumidity = 216.7f * ((humidity / 100.0f) * 6.112f * exp((17.62f * temperature) / (243.12f + temperature))) / (273.15f + temperature);
  const uint32_t absoluteHumidityScaled = static_cast<uint32_t>(absoluteHumidity * 1000.0f); // Scale to mg/m³
  return absoluteHumidityScaled;
}

void setup()
{
  // put your setup code here, to run once:
  Serial.begin(115200);
  dht.begin();
  if (!sgp.begin()){
    Serial.println("Sensor not found :(");
    while(1);
  }
  Serial.println("ESP32 DHT22 Node Ready");
    // Connect to WiFi
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    Serial.print("Connecting to WiFi");
    while (WiFi.status() != WL_CONNECTED) {
        Serial.print(".");
        delay(500);
    }
    Serial.println("\nConnected!");
    // Configure Firebase
    config.api_key = API_KEY;
    config.database_url = DATABASE_URL;
    config.token_status_callback = tokenStatusCallback;
    // Sign in anonymously
    auth.user.email = "esp32@Airguard.com";
    auth.user.password = "AirguardHomeTest";
    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);
=======
// ── Intervals ─────────────────────────────────────────────
#define SEND_INTERVAL   10000  // Send to Firebase every 10s
#define SGP30_INTERVAL   1000  // SGP30 must be read every 1s for baseline accuracy

// ── Objects ───────────────────────────────────────────────
DHT              dht(DHTPIN, DHTTYPE);
Adafruit_PM25AQI pmsa;
Adafruit_SGP30   sgp;
FirebaseData     fbdo;
FirebaseAuth     auth;
FirebaseConfig   config;

// ── State ─────────────────────────────────────────────────
unsigned long lastSendTime  = 0;
unsigned long lastSGP30Time = 0;
bool pmsaReady = false;
bool sgpReady  = false;

// ── Latest SGP30 readings (updated every 1s) ──────────────
uint16_t latest_tvoc = 0;
uint16_t latest_eco2 = 0;

// ─────────────────────────────────────────────────────────
//  SGP30 Absolute Humidity Helper
//  Feeding humidity improves TVOC/eCO2 accuracy
// ─────────────────────────────────────────────────────────
uint32_t getAbsoluteHumidity(float temperature, float humidity) {
  const float absHumidity =
    216.7f * ((humidity / 100.0f) * 6.112f *
    exp((17.62f * temperature) / (243.12f + temperature)) /
    (273.15f + temperature));
  const uint32_t absHumidityScaled =
    static_cast<uint32_t>(1000.0f * absHumidity);
  return (absHumidityScaled >> 8) | ((absHumidityScaled & 0xFF) << 8);
}

// ─────────────────────────────────────────────────────────
//  WiFi
// ─────────────────────────────────────────────────────────
void connectWiFi() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
>>>>>>> bdb0da68d4b6340f3019eda9f04aa0022b85c78c
  }
  Serial.println("\nWiFi Connected! IP: " + WiFi.localIP().toString());
}

// ─────────────────────────────────────────────────────────
//  Firebase
// ─────────────────────────────────────────────────────────
void connectFirebase() {
  config.api_key               = API_KEY;
  config.database_url          = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;

  auth.user.email    = "esp32@Airguard.com";
  auth.user.password = "AirguardHomeTest";

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  Serial.println("Firebase initialised");
}

// ─────────────────────────────────────────────────────────
//  Poll SGP30 — must be called every 1 second
// ─────────────────────────────────────────────────────────
void pollSGP30() {
  if (!sgpReady) return;

  if (millis() - lastSGP30Time >= SGP30_INTERVAL) {
    lastSGP30Time = millis();

    // Feed absolute humidity from DHT22 for compensation
    float h = dht.readHumidity();
    float t = dht.readTemperature();
    if (!isnan(h) && !isnan(t)) {
      sgp.setHumidity(getAbsoluteHumidity(t, h));
    }

    if (!sgp.IAQmeasure()) {
      Serial.println("[SGP30] ERROR: Measurement failed!");
      return;
    }

    latest_tvoc = sgp.TVOC;
    latest_eco2 = sgp.eCO2;
  }
}

// ─────────────────────────────────────────────────────────
//  Send DHT22 Data
// ─────────────────────────────────────────────────────────
void sendDHTData() {
  float humidity    = dht.readHumidity();
  float temperature = dht.readTemperature();

  if (isnan(humidity) || isnan(temperature)) {
    Serial.println("[DHT22] ERROR: Failed to read sensor!");
    return;
  }
  if (temperature < -40 || temperature > 80) {
    Serial.println("[DHT22] ERROR: Temperature out of range, skipping...");
    return;
  }
  if (humidity < 0 || humidity > 100) {
    Serial.println("[DHT22] ERROR: Humidity out of range, skipping...");
    return;
  }
  sgp.setHumidity(getAbsoluteHumidity(temperature, humidity));
  if (! sgp.IAQmeasure()){
    Serial.println("Failed to perform IAQ measurement");
    return;
  }


  float heatIndex = dht.computeHeatIndex(temperature, humidity, false);

  Serial.printf("[DHT22] Temp: %.2f°C | Humidity: %.2f%% | HeatIndex: %.2f°C\n",
                temperature, humidity, heatIndex);
<<<<<<< HEAD
  
  Serial.printf("eCO2: %d ppm | TVOC: %d ppb\n", sgp.eCO2, sgp.TVOC);
  // Only send if Firebase is ready
  if (Firebase.ready()) {
    bool tempOk = Firebase.RTDB.setFloat(&fbdo, "/airguard/temperature", temperature);
    bool humOk  = Firebase.RTDB.setFloat(&fbdo, "/airguard/humidity", humidity);
    bool hiOk   = Firebase.RTDB.setFloat(&fbdo, "/airguard/heatIndex", heatIndex);
    bool eco2Ok = Firebase.RTDB.setInt(&fbdo, "/airguard/eco2", sgp.eCO2);
    bool tvocOk = Firebase.RTDB.setInt(&fbdo, "/airguard/tvoc", sgp.TVOC);

    if (tempOk && humOk && hiOk) {
      Serial.println("Firebase updated successfully");
      Serial.printf("Sent → Temp: %.2f | Humidity: %.2f | Heat Index: %.2f\n",
                    temperature, humidity, heatIndex);
    } else {
      if (!tempOk) Serial.println("Temp failed: " + fbdo.errorReason());
      if (!humOk)  Serial.println("Humidity failed: " + fbdo.errorReason());
      if (!hiOk)   Serial.println("Heat Index failed: " + fbdo.errorReason());
    }

    if (eco2Ok && tvocOk) {
      Serial.println("Firebase (SGP30 Data) updated successfully");
      Serial.printf("Sent → eCO2: %d ppm | TVOC: %d ppb\n", sgp.eCO2, sgp.TVOC);
    } else {
      if (!eco2Ok) Serial.println("eCO2 failed: " + fbdo.errorReason());
      if (!tvocOk) Serial.println("TVOC failed: " + fbdo.errorReason());
    }
=======

  bool t = Firebase.RTDB.setFloat(&fbdo, "/airguard/dht22/temperature", temperature);
  bool h = Firebase.RTDB.setFloat(&fbdo, "/airguard/dht22/humidity",    humidity);
  bool i = Firebase.RTDB.setFloat(&fbdo, "/airguard/dht22/heatIndex",   heatIndex);

  if (t && h && i) {
    Serial.println("[DHT22] Firebase updated ✔");
  } else {
    if (!t) Serial.println("[DHT22] Temp failed:      " + fbdo.errorReason());
    if (!h) Serial.println("[DHT22] Humidity failed:  " + fbdo.errorReason());
    if (!i) Serial.println("[DHT22] HeatIndex failed: " + fbdo.errorReason());
>>>>>>> bdb0da68d4b6340f3019eda9f04aa0022b85c78c
  }
}

// ─────────────────────────────────────────────────────────
//  Send PM25AQI Air Quality Data
// ─────────────────────────────────────────────────────────
void sendAirQualityData() {
  PM25_AQI_Data data;

  if (!pmsa.read(&data)) {
    Serial.println("[PM25AQI] ERROR: Failed to read sensor!");
    return;
  }

  uint16_t pm10_std  = data.pm10_standard;
  uint16_t pm25_std  = data.pm25_standard;
  uint16_t pm100_std = data.pm100_standard;
  uint16_t pm10_env  = data.pm10_env;
  uint16_t pm25_env  = data.pm25_env;
  uint16_t pm100_env = data.pm100_env;
  uint16_t p03um     = data.particles_03um;
  uint16_t p05um     = data.particles_05um;
  uint16_t p10um     = data.particles_10um;
  uint16_t p25um     = data.particles_25um;
  uint16_t p50um     = data.particles_50um;
  uint16_t p100um    = data.particles_100um;

  String aqiLabel;
  if      (pm25_env <= 12)  aqiLabel = "Good";
  else if (pm25_env <= 35)  aqiLabel = "Moderate";
  else if (pm25_env <= 55)  aqiLabel = "Unhealthy for Sensitive Groups";
  else if (pm25_env <= 150) aqiLabel = "Unhealthy";
  else if (pm25_env <= 250) aqiLabel = "Very Unhealthy";
  else                      aqiLabel = "Hazardous";

  Serial.println("[PM25AQI] ── Particulate Readings ──────────────");
  Serial.printf("  PM1.0: %d | PM2.5: %d | PM10: %d µg/m³ (standard)\n",
                pm10_std, pm25_std, pm100_std);
  Serial.printf("  PM1.0: %d | PM2.5: %d | PM10: %d µg/m³ (env)\n",
                pm10_env, pm25_env, pm100_env);
  Serial.printf("  AQI Category: %s\n", aqiLabel.c_str());

  Firebase.RTDB.setInt(&fbdo,    "/airguard/airquality/pm1_0_standard",  pm10_std);
  Firebase.RTDB.setInt(&fbdo,    "/airguard/airquality/pm2_5_standard",  pm25_std);
  Firebase.RTDB.setInt(&fbdo,    "/airguard/airquality/pm10_standard",   pm100_std);
  Firebase.RTDB.setInt(&fbdo,    "/airguard/airquality/pm1_0_env",       pm10_env);
  Firebase.RTDB.setInt(&fbdo,    "/airguard/airquality/pm2_5_env",       pm25_env);
  Firebase.RTDB.setInt(&fbdo,    "/airguard/airquality/pm10_env",        pm100_env);
  Firebase.RTDB.setInt(&fbdo,    "/airguard/airquality/particles_03um",  p03um);
  Firebase.RTDB.setInt(&fbdo,    "/airguard/airquality/particles_05um",  p05um);
  Firebase.RTDB.setInt(&fbdo,    "/airguard/airquality/particles_10um",  p10um);
  Firebase.RTDB.setInt(&fbdo,    "/airguard/airquality/particles_25um",  p25um);
  Firebase.RTDB.setInt(&fbdo,    "/airguard/airquality/particles_50um",  p50um);
  Firebase.RTDB.setInt(&fbdo,    "/airguard/airquality/particles_100um", p100um);
  Firebase.RTDB.setString(&fbdo, "/airguard/airquality/aqi_category",    aqiLabel);

  Serial.println("[PM25AQI] Firebase updated ✔");
}

// ─────────────────────────────────────────────────────────
//  Send SGP30 Gas Sensor Data
// ─────────────────────────────────────────────────────────
void sendSGP30Data() {
  if (!sgpReady) {
    Serial.println("[SGP30] Skipping — sensor not available");
    return;
  }

  // ── TVOC classification ─────────────────────────────────
  String tvocLabel;
  if      (latest_tvoc <= 220)  tvocLabel = "Good";
  else if (latest_tvoc <= 660)  tvocLabel = "Moderate";
  else if (latest_tvoc <= 2200) tvocLabel = "Unhealthy";
  else                          tvocLabel = "Hazardous";

  // ── eCO2 classification ─────────────────────────────────
  String eco2Label;
  if      (latest_eco2 <= 600)  eco2Label = "Excellent";
  else if (latest_eco2 <= 800)  eco2Label = "Good";
  else if (latest_eco2 <= 1000) eco2Label = "Moderate";
  else if (latest_eco2 <= 1500) eco2Label = "Poor";
  else                          eco2Label = "Hazardous";

  Serial.println("[SGP30] ── Gas Sensor Readings ─────────────────");
  Serial.printf("  TVOC: %d ppb  → %s\n", latest_tvoc, tvocLabel.c_str());
  Serial.printf("  eCO2: %d ppm  → %s\n", latest_eco2, eco2Label.c_str());

  // Note: SGP30 outputs 400ppm eCO2 and 0ppb TVOC on first 15s of boot
  // This is normal — sensor needs ~15s warm-up time
  if (latest_eco2 == 400 && latest_tvoc == 0) {
    Serial.println("[SGP30] Warming up — readings not yet valid (normal for first 15s)");
  }

  bool tv = Firebase.RTDB.setInt(&fbdo,    "/airguard/gas/tvoc_ppb",      latest_tvoc);
  bool ec = Firebase.RTDB.setInt(&fbdo,    "/airguard/gas/eco2_ppm",      latest_eco2);
  bool tl = Firebase.RTDB.setString(&fbdo, "/airguard/gas/tvoc_category", tvocLabel);
  bool el = Firebase.RTDB.setString(&fbdo, "/airguard/gas/eco2_category", eco2Label);

  if (tv && ec && tl && el) {
    Serial.println("[SGP30] Firebase updated ✔");
  } else {
    if (!tv) Serial.println("[SGP30] TVOC failed:      " + fbdo.errorReason());
    if (!ec) Serial.println("[SGP30] eCO2 failed:      " + fbdo.errorReason());
    if (!tl) Serial.println("[SGP30] TVOC label failed: " + fbdo.errorReason());
    if (!el) Serial.println("[SGP30] eCO2 label failed: " + fbdo.errorReason());
  }
}

// ─────────────────────────────────────────────────────────
//  Setup
// ─────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  Serial.println("AirGuardHome — Booting...");

  Wire.begin(); // SDA=GPIO21, SCL=GPIO22

  dht.begin();
  Serial.println("[DHT22] Initialised");

  // Init PMSA003I
  if (!pmsa.begin_I2C()) {
    Serial.println("[PM25AQI] ERROR: Sensor not found! Check wiring.");
    pmsaReady = false;
  } else {
    Serial.println("[PM25AQI] Sensor found at 0x12 ✔");
    pmsaReady = true;
  }

  // Init SGP30
  if (!sgp.begin()) {
    Serial.println("[SGP30] ERROR: Sensor not found! Check wiring.");
    sgpReady = false;
  } else {
    Serial.printf("[SGP30] Sensor found at 0x58 ✔ — Serial: 0x%02X%02X%02X\n",
                  sgp.serialnumber[0], sgp.serialnumber[1], sgp.serialnumber[2]);
    sgpReady = true;
  }

  connectWiFi();
  connectFirebase();

  Serial.println("All systems ready — starting readings...\n");
}

// ─────────────────────────────────────────────────────────
//  Loop
// ─────────────────────────────────────────────────────────
void loop() {
  // Poll SGP30 every 1 second (required for internal baseline algorithm)
  pollSGP30();

  // Send all data to Firebase every 10 seconds
  if (millis() - lastSendTime >= SEND_INTERVAL) {
    lastSendTime = millis();

    Serial.println("══════════════════════════════════════════");

    if (Firebase.ready()) {
      sendDHTData();
      if (pmsaReady) sendAirQualityData();
      sendSGP30Data();
    } else {
      Serial.println("[Firebase] Not ready, skipping cycle...");
    }

    Serial.println("══════════════════════════════════════════\n");
  }
}