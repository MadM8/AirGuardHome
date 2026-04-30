#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include "sensors.h"

// ─── Credentials ─────────────────────────────────────────────────────────────
#define WIFI_SSID     "iPhone 4s"
#define WIFI_PASSWORD "GusPirate"
#define API_KEY       "AIzaSyANUJRVCvBLFiWtJSqP6NS7wVZuSINySik"
#define DATABASE_URL  "https://airguardfire-default-rtdb.firebaseio.com"
#define FB_EMAIL      "esp32@Airguard.com"
#define FB_PASSWORD   "AirguardHomeTest"

static FirebaseData   fbdo;
static FirebaseAuth   auth;
static FirebaseConfig config;
static bool           fbReady = false;

// ─── Seed the history ring buffer ────────────────────────────────────────────
void seedHistory(AppState &s) {
    float t = 71.0f;
    for (int i = 0; i < AppState::HIST_SIZE; i++) {
        t += (float)(random(-15, 16)) / 10.0f;
        t  = constrain(t, 67.0f, 77.0f);
        s.tempHistory[i] = t;
    }
    s.histCount = AppState::HIST_SIZE;
    s.histIdx   = 0;
}

// ─── Hardware + WiFi + Firebase init ─────────────────────────────────────────
void sensorsInit() {
    Serial.begin(115200);

    // Connect WiFi
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    Serial.print("Connecting to WiFi");
    unsigned long start = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - start < 10000) {
        Serial.print(".");
        delay(500);
    }
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nWiFi connected!");
    } else {
        Serial.println("\nWiFi failed — running without Firebase");
        return;
    }

    // Configure Firebase
    config.api_key       = API_KEY;
    config.database_url  = DATABASE_URL;
    config.token_status_callback = tokenStatusCallback;

    auth.user.email    = FB_EMAIL;
    auth.user.password = FB_PASSWORD;

    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);
    fbReady = true;
    Serial.println("Firebase initialised");
}

// ─── Called every loop() ─────────────────────────────────────────────────────
void sensorsUpdate(AppState &s) {
    unsigned long now = millis();

    // ── Firebase: poll every 5 seconds ───────────────────────────────────────
    constexpr unsigned long FB_INTERVAL = 5000;
    if (fbReady && Firebase.ready() && now - s.lastSensorRead >= FB_INTERVAL) {
        s.lastSensorRead = now;

        // Temperature — stored as °C, convert to °F for display
        float tempC = 0;
        if (Firebase.RTDB.getFloat(&fbdo, "/airguard/dht22/temperature", &tempC)) {
            s.currTemp = (tempC * 9.0f / 5.0f) + 32.0f;
            Serial.printf("[Firebase] Temp: %.1f°C → %.1f°F\n", tempC, s.currTemp);
        } else {
            Serial.println("[Firebase] Temp read failed: " + fbdo.errorReason());
        }

        // Humidity
        float hum = 0;
        if (Firebase.RTDB.getFloat(&fbdo, "/airguard/dht22/humidity", &hum)) {
            s.humidity = hum;
            Serial.printf("[Firebase] Humidity: %.1f%%\n", hum);
        }

        // Push to history ring buffer
        s.tempHistory[s.histIdx] = s.currTemp;
        s.histIdx = (s.histIdx + 1) % AppState::HIST_SIZE;
        if (s.histCount < AppState::HIST_SIZE) s.histCount++;

        s.dirty = true;
    }

    // ── Fallback simulation if WiFi/Firebase not available ───────────────────
    constexpr unsigned long SIM_INTERVAL = 3000;
    if (!fbReady && now - s.lastSimUpdate >= SIM_INTERVAL) {
        s.lastSimUpdate = now;

        s.currTemp += (float)(random(-5, 6)) / 10.0f;
        s.currTemp  = constrain(s.currTemp, 68.0f, 76.0f);
        s.humidity += (float)(random(-10, 11)) / 10.0f;
        s.humidity  = constrain(s.humidity, 40.0f, 80.0f);
        s.aqi       = constrain(s.aqi + (int)random(-3, 4), 30, 150);
        s.co2       = constrain(s.co2 + (int)random(-20, 21), 400, 1400);

        s.tempHistory[s.histIdx] = s.currTemp;
        s.histIdx = (s.histIdx + 1) % AppState::HIST_SIZE;
        if (s.histCount < AppState::HIST_SIZE) s.histCount++;

        s.dirty = true;
    }
}