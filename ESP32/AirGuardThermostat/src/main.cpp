/*
 * M5Stack Dial — HVAC Smart Thermostat
 * ═══════════════════════════════════════════════════════════════════════════
 * PlatformIO / VS Code project
 * Target: M5Stack Dial (ESP32-S3 + GC9A01 round 240×240 display)
 *
 * Controls
 *   Rotate encoder  → adjust set-temp (Page 1) / history timeframe (Page 2)
 *   Short press     → next page  (Thermo → History → Alerts → Thermo)
 *   Long press >0.6s→ cycle HVAC mode on Page 1
 *
 * Optional sensors (Grove PORT-A, SDA=13 SCL=15):
 *   SHT31  — temperature + humidity
 *   ENS160 — AQI + eCO2
 *   Uncomment the sensor blocks in sensors.cpp to enable.
 */

#include <M5Dial.h>
#include <M5GFX.h>
#include "thermostat.h"
#include "input.h"
#include "sensors.h"
#include "ui.h"

// ─── Globals shared across modules ───────────────────────────────────────────
AppState     state;
M5GFX       &lcd    = M5Dial.Display;
M5Canvas     canvas(&lcd);

// ─────────────────────────────────────────────────────────────────────────────
void setup() {
    auto cfg = M5.config();
    M5Dial.begin(cfg, /*encoder=*/true, /*rfid=*/false);

    lcd.setRotation(0);
    lcd.setBrightness(210);

    canvas.createSprite(240, 240);

    sensorsInit();
    seedHistory(state);
}

// ─────────────────────────────────────────────────────────────────────────────
void loop() {
    M5Dial.update();

    handleEncoder(state);
    handleButton(state);
    sensorsUpdate(state);

    if (state.dirty) {
        drawFrame(canvas, state);
        canvas.pushSprite(0, 0);
        state.dirty = false;
    }

    delay(16);   // ~60 fps cap
}
