#include <M5Dial.h>
#include "input.h"

// Mode button hit zone — must match what ui.cpp draws
constexpr int MODE_BTN_X = 70;   // left edge
constexpr int MODE_BTN_Y = 178;  // top edge
constexpr int MODE_BTN_W = 100;
constexpr int MODE_BTN_H = 24;

// ─── Encoder ─────────────────────────────────────────────────────────────────
void handleEncoder(AppState &s) {
    long enc   = M5Dial.Encoder.read();
    long delta = enc - s.lastEnc;
    if (delta == 0) return;
    s.lastEnc = enc;
    s.dirty   = true;

    switch (s.page) {
        case Page::THERMO:
            s.setTemp = constrain(s.setTemp + (int)delta, TEMP_MIN, TEMP_MAX);
            break;
        case Page::HISTORY:
            s.histFrame = constrain(s.histFrame + (int)delta, 0, 3);
            break;
        case Page::ALERTS:
            break;
    }
}

// ─── Button + Touch ───────────────────────────────────────────────────────────
void handleButton(AppState &s) {
    // Short press → next page
    if (M5Dial.BtnA.wasPressed()) {
        int next = ((int)s.page + 1) % 3;
        s.page   = (Page)next;
        s.dirty  = true;
    }

    // Touch → cycle HVAC mode when tapped on mode button (Page 1 only)
    if (s.page == Page::THERMO) {
        auto touch = M5Dial.Touch.getDetail();
        if (touch.wasClicked()) {
            int tx = touch.x;
            int ty = touch.y;

            // Check if tap was inside the mode button
            if (tx >= MODE_BTN_X && tx <= MODE_BTN_X + MODE_BTN_W &&
                ty >= MODE_BTN_Y && ty <= MODE_BTN_Y + MODE_BTN_H) {
                int next = ((int)s.mode + 1) % 4;
                s.mode   = (HvacMode)next;
                s.dirty  = true;
                Serial.printf("[Touch] Mode changed to %d\n", (int)s.mode);
            }
        }
    }
}