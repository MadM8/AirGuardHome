#include <Arduino.h>
#include <DHT.h>
#include <WiFi.h>
#include <Wire.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include "Adafruit_SGP30.h"

#define DHTPIN 4      // GPIO pin connected to DHT22 DATA
#define DHTTYPE DHT22 // Sensor type


// WiFi credentials
#define WIFI_SSID "iPhone 4s"
#define WIFI_PASSWORD "GusPirate"

// Firebase credentials
#define API_KEY "AIzaSyANUJRVCvBLFiWtJSqP6NS7wVZuSINySik"
#define DATABASE_URL "https://airguardfire-default-rtdb.firebaseio.com/"
//#define USER_EMAIL "ramadridq@gmail.com"
//#define USER_PASSWORD ""

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
  }
  
void loop() {
  delay(2000);

  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature();
  float heatIndex = dht.computeHeatIndex(temperature, humidity, false);

  // Check for failed readings
  if (isnan(humidity) || isnan(temperature)) {
    Serial.println("ERROR: Failed to read from DHT22!");
    return;
  }

  // Sanity check - DHT22 valid ranges
  if (temperature < -40 || temperature > 80) {
    Serial.println("ERROR: Temperature out of range, skipping...");
    return;
  }
  if (humidity < 0 || humidity > 100) {
    Serial.println("ERROR: Humidity out of range, skipping...");
    return;
  }
  sgp.setHumidity(getAbsoluteHumidity(temperature, humidity));
  if (! sgp.IAQmeasure()){
    Serial.println("Failed to perform IAQ measurement");
    return;
  }


  Serial.printf("Temp: %.2f°C | Humidity: %.2f%% | Heat Index: %.2f°C\n",
                temperature, humidity, heatIndex);
  
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
  }
}
// put function definitions here:
int myFunction(int x, int y)
{
  return x + y;
}