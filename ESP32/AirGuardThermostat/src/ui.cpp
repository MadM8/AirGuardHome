/*
 * ui.cpp — All display rendering for the HVAC thermostat
 */

#include <M5GFX.h>
#include <math.h>
#include "ui.h"

// ─────────────────────────────────────────────────────────────────────────────
//  Top-level frame dispatcher
// ─────────────────────────────────────────────────────────────────────────────
void drawFrame(M5Canvas &canvas, const AppState &s) {
    canvas.fillScreen(COL_BG);

    switch (s.page) {
        case Page::THERMO:  drawThermoPage (canvas, s); break;
        case Page::HISTORY: drawHistoryPage(canvas, s); break;
        case Page::ALERTS:  drawAlertsPage (canvas, s); break;
    }

    drawPageDots(canvas, s);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared: page-indicator dots at bottom of screen
// ─────────────────────────────────────────────────────────────────────────────
void drawPageDots(M5Canvas &canvas, const AppState &s) {
    constexpr int cy = 225, spacing = 12, cx = 120;
    for (int i = 0; i < 3; i++) {
        int x = cx + (i - 1) * spacing;
        if (i == (int)s.page) {
            canvas.fillCircle(x, cy, 3, COL_ACCENT_BLUE);
        } else {
            canvas.fillCircle(x, cy, 2, COL_TRACK);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared: rasterise an arc as a series of filled circles
// ─────────────────────────────────────────────────────────────────────────────
void drawArcSegment(M5Canvas &canvas, int cx, int cy, int r, int w,
                    float startDeg, float sweepDeg, uint16_t color) {
    if (sweepDeg <= 0) return;
    int steps = max(1, (int)(sweepDeg * 1.8f));
    for (int i = 0; i <= steps; i++) {
        float angle = (startDeg + sweepDeg * i / steps) * DEG_TO_RAD;
        int x = cx + (int)(r * cosf(angle));
        int y = cy + (int)(r * sinf(angle));
        canvas.fillCircle(x, y, w / 2, color);
    }
}

// ══════════════════════════════════════════════════════════════════════════════
//  PAGE 1 — THERMOSTAT
// ══════════════════════════════════════════════════════════════════════════════
static void drawArc(M5Canvas &canvas, const AppState &s) {
    constexpr int   cx = 120, cy = 120, r = 104, trackW = 5;
    constexpr float START_DEG = 155.0f;
    constexpr float SWEEP_DEG = 230.0f;

    // Background track
    drawArcSegment(canvas, cx, cy, r, trackW, START_DEG, SWEEP_DEG, COL_TRACK);

    // Active fill proportional to setTemp
    float pct  = (float)(s.setTemp - TEMP_MIN) / (float)(TEMP_MAX - TEMP_MIN);
    float fill = SWEEP_DEG * pct;

    uint16_t arcColor = COL_ACCENT_BLUE;
    if      (s.mode == HvacMode::HEAT) arcColor = COL_AMBER;
    else if (s.mode == HvacMode::FAN  ||
             s.mode == HvacMode::AUTO) arcColor = COL_ACCENT_GREEN;

    drawArcSegment(canvas, cx, cy, r, trackW, START_DEG, fill, arcColor);

    // Endpoint tick
    float tickRad = (START_DEG + fill) * DEG_TO_RAD;
    int   tx = cx + (int)((r - 1) * cosf(tickRad));
    int   ty = cy + (int)((r - 1) * sinf(tickRad));
    canvas.fillCircle(tx, ty, 5, arcColor);
}

void drawThermoPage(M5Canvas &canvas, const AppState &s) {
    drawArc(canvas, s);

    canvas.setTextDatum(MC_DATUM);

    // "INDOOR" label
    canvas.setFont(&fonts::FreeMono9pt7b);
    canvas.setTextColor(COL_MUTED, COL_BG);
    canvas.drawString("INDOOR", 120, 88);

    // Current temperature (large)
    char buf[12];
    canvas.setFont(&fonts::FreeSansBold18pt7b);
    canvas.setTextColor(COL_TEXT, COL_BG);
    snprintf(buf, sizeof(buf), "%d", (int)roundf(s.currTemp));
    canvas.drawString(buf, 115, 118);

    // Degree symbol + F
    canvas.setFont(&fonts::FreeSans9pt7b);
    canvas.setTextColor(COL_MUTED, COL_BG);
    canvas.drawString("oF", 148, 104);

    // Set-point row
    canvas.setFont(&fonts::FreeMono9pt7b);
    canvas.setTextColor(COL_MUTED, COL_BG);
    canvas.drawString("SET", 96, 144);
    canvas.setTextColor(COL_ACCENT_BLUE, COL_BG);
    snprintf(buf, sizeof(buf), "%doF", s.setTemp);
    canvas.drawString(buf, 150, 144);

    // ── HVAC Mode Button (tappable) ──────────────────────────────────────────
    static const char*     modeStr[] = { "COOLING", "HEATING", "FAN ONLY", "AUTO" };
    static const char*     modeIcon[]= { " < ",     " > ",     "~~~",      " = " };
    static const uint16_t  modeCol[] = {
        COL_ACCENT_GREEN, COL_AMBER, COL_ACCENT_BLUE, 0xC3BF
    };

    uint16_t mc = modeCol[(int)s.mode];

    // Button background
    constexpr int bx = 70, by = 178, bw = 100, bh = 24, br = 8;
    canvas.fillRoundRect(bx, by, bw, bh, br, COL_CARD);
    canvas.drawRoundRect(bx, by, bw, bh, br, mc);

    // Mode text inside button
    canvas.setTextDatum(MC_DATUM);
    canvas.setFont(&fonts::FreeMono9pt7b);
    canvas.setTextColor(mc, COL_CARD);
    snprintf(buf, sizeof(buf), "%s %s", modeIcon[(int)s.mode], modeStr[(int)s.mode]);
    canvas.drawString(modeStr[(int)s.mode], bx + bw / 2, by + bh / 2);

    // Small "tap to change" hint below button
    canvas.setFont(&fonts::FreeMono9pt7b);
    canvas.setTextColor(COL_TRACK, COL_BG);
    canvas.drawString("tap to change", 120, 210);
}

// ══════════════════════════════════════════════════════════════════════════════
//  PAGE 2 — TEMPERATURE HISTORY
// ══════════════════════════════════════════════════════════════════════════════
void drawHistoryPage(M5Canvas &canvas, const AppState &s) {
    canvas.setTextDatum(MC_DATUM);
    canvas.setFont(&fonts::FreeMono9pt7b);
    canvas.setTextColor(COL_ACCENT_BLUE, COL_BG);
    canvas.drawString("TEMP HISTORY", 120, 28);

    // Number of samples to display per timeframe
    static const int sampleCounts[] = { 24, 36, 48, 96 };
    int samples = min(sampleCounts[s.histFrame], s.histCount);

    // Chart area
    constexpr int cx = 18, cy = 45, cw = 204, ch = 115;
    canvas.drawRect(cx, cy, cw, ch, COL_TRACK);

    if (samples > 1) {
        // Find visible window min/max
        float mn = 999.0f, mx = -999.0f;
        int start = (s.histIdx - samples + AppState::HIST_SIZE) % AppState::HIST_SIZE;

        for (int i = 0; i < samples; i++) {
            float v = s.tempHistory[(start + i) % AppState::HIST_SIZE];
            mn = min(mn, v);
            mx = max(mx, v);
        }
        mn -= 1.0f;
        mx += 1.0f;
        float range = max(mx - mn, 2.0f);

        // Y-axis labels
        char buf[8];
        canvas.setTextDatum(MR_DATUM);
        canvas.setTextColor(COL_MUTED, COL_BG);
        snprintf(buf, sizeof(buf), "%d", (int)roundf(mx));
        canvas.drawString(buf, cx - 2, cy + 5);
        snprintf(buf, sizeof(buf), "%d", (int)roundf(mn));
        canvas.drawString(buf, cx - 2, cy + ch - 5);

        // Fill + line
        for (int i = 1; i < samples; i++) {
            float v0 = s.tempHistory[(start + i - 1) % AppState::HIST_SIZE];
            float v1 = s.tempHistory[(start + i)     % AppState::HIST_SIZE];

            int x0 = cx + (int)((float)(i - 1) / (samples - 1) * cw);
            int x1 = cx + (int)((float) i       / (samples - 1) * cw);
            int y0 = cy + ch - (int)((v0 - mn) / range * ch);
            int y1 = cy + ch - (int)((v1 - mn) / range * ch);

            // Filled area (dark blue tint below line)
            canvas.drawLine(x1, y1, x1, cy + ch, canvas.color565(18, 38, 72));
            // Line
            canvas.drawLine(x0, y0, x1, y1, COL_ACCENT_BLUE);
        }
    }

    // ── Timeframe selector buttons ──────────────────────────────────────────
    constexpr int btnW = 38, btnH = 20, gap = 7;
    constexpr int totalW = 4 * btnW + 3 * gap;
    constexpr int startX = (240 - totalW) / 2;
    constexpr int btnY   = 172;

    static const char* frameLabels[] = { "1D", "3D", "7D", "30D" };

    for (int i = 0; i < 4; i++) {
        int bx     = startX + i * (btnW + gap);
        bool active = (i == s.histFrame);

        canvas.fillRoundRect(bx, btnY, btnW, btnH, 6,
            active ? COL_ACCENT_BLUE : COL_CARD);
        canvas.drawRoundRect(bx, btnY, btnW, btnH, 6,
            active ? COL_ACCENT_BLUE : COL_TRACK);

        canvas.setTextDatum(MC_DATUM);
        canvas.setFont(&fonts::FreeMono9pt7b);
        canvas.setTextColor(
            active ? COL_TEXT  : COL_MUTED,
            active ? COL_ACCENT_BLUE : COL_CARD
        );
        canvas.drawString(frameLabels[i], bx + btnW / 2, btnY + btnH / 2);
    }

    // Hint
    canvas.setTextDatum(MC_DATUM);
    canvas.setFont(&fonts::FreeMono9pt7b);
    canvas.setTextColor(COL_TRACK, COL_BG);
    canvas.drawString("rotate to change range", 120, 202);
}

// ══════════════════════════════════════════════════════════════════════════════
//  PAGE 3 — ALERTS
// ══════════════════════════════════════════════════════════════════════════════
void drawAlertsPage(M5Canvas &canvas, const AppState &s) {
    canvas.setTextDatum(MC_DATUM);
    canvas.setFont(&fonts::FreeMono9pt7b);
    canvas.setTextColor(COL_AMBER, COL_BG);
    canvas.drawString("ALERTS", 120, 26);

    // Build alert list from live state
    Alert alerts[5];
    int   count = 0;

    // Filter alert — always shown
    {
        Alert &a = alerts[count++];
        strncpy(a.title, "Replace air filter", sizeof(a.title));
        if (s.filterDays >= FILTER_LIFE_DAYS) {
            snprintf(a.detail, sizeof(a.detail), "OVERDUE: day %d — change now", s.filterDays);
            a.dotColor = COL_RED;
        } else {
            snprintf(a.detail, sizeof(a.detail), "Day %d of %d — due soon", s.filterDays, FILTER_LIFE_DAYS);
            a.dotColor = COL_AMBER;
        }
    }

    // Humidity
    if (s.humidity > HUMIDITY_HIGH) {
        Alert &a = alerts[count++];
        strncpy(a.title, "High humidity", sizeof(a.title));
        snprintf(a.detail, sizeof(a.detail), "%.0f%% RH  comfort max %.0f%%",
            s.humidity, HUMIDITY_HIGH);
        a.dotColor = COL_AMBER;
    }

    // AQI
    if (s.aqi > AQI_MODERATE) {
        Alert &a = alerts[count++];
        strncpy(a.title, "Air quality alert", sizeof(a.title));
        snprintf(a.detail, sizeof(a.detail), "AQI %d  moderate — check filter", s.aqi);
        a.dotColor = COL_AMBER;
    }

    // CO2
    if (s.co2 > CO2_HIGH) {
        Alert &a = alerts[count++];
        strncpy(a.title, "CO2 elevated", sizeof(a.title));
        snprintf(a.detail, sizeof(a.detail), "%d ppm  open a window", s.co2);
        a.dotColor = COL_RED;
    }

    // All-clear (shown only when no dynamic alerts)
    if (s.humidity <= HUMIDITY_HIGH && s.aqi <= AQI_MODERATE && s.co2 <= CO2_HIGH) {
        Alert &a = alerts[count++];
        strncpy(a.title,  "Air quality normal", sizeof(a.title));
        strncpy(a.detail, "All sensors within range", sizeof(a.detail));
        a.dotColor = COL_ACCENT_GREEN;
    }

    // Draw up to 4 cards
    constexpr int itemH = 36, startY = 42, itemGap = 5;
    int shown = min(count, 4);

    for (int i = 0; i < shown; i++) {
        int y = startY + i * (itemH + itemGap);
        canvas.fillRoundRect(16, y, 208, itemH, 5, COL_CARD);
        canvas.fillCircle(26, y + itemH / 2, 4, alerts[i].dotColor);

        canvas.setTextDatum(ML_DATUM);
        canvas.setFont(&fonts::FreeMono9pt7b);
        canvas.setTextColor(COL_TEXT, COL_CARD);
        canvas.drawString(alerts[i].title,  38, y + 11);
        canvas.setTextColor(COL_MUTED, COL_CARD);
        canvas.drawString(alerts[i].detail, 38, y + 26);
    }
}
