#pragma once
#include <Arduino.h>

// ─── Thresholds ──────────────────────────────────────────────────────────────
constexpr int   TEMP_MIN          = 60;
constexpr int   TEMP_MAX          = 85;
constexpr int   FILTER_LIFE_DAYS  = 90;
constexpr float HUMIDITY_HIGH     = 60.0f;
constexpr int   AQI_MODERATE      = 51;
constexpr int   CO2_HIGH          = 1000;

// ─── Display colors (RGB565) ─────────────────────────────────────────────────
constexpr uint16_t COL_BG           = 0x0841;
constexpr uint16_t COL_TRACK        = 0x1082;
constexpr uint16_t COL_ACCENT_BLUE  = 0x2C7F;
constexpr uint16_t COL_ACCENT_GREEN = 0x1EEF;
constexpr uint16_t COL_AMBER        = 0xE4C4;
constexpr uint16_t COL_RED          = 0xE88A;
constexpr uint16_t COL_TEXT         = 0xEF7D;
constexpr uint16_t COL_MUTED        = 0x8430;
constexpr uint16_t COL_CARD         = 0x18A3;

// ─── Enums ───────────────────────────────────────────────────────────────────
enum class Page { THERMO, HISTORY, ALERTS };
enum class HvacMode { COOL, HEAT, FAN, AUTO };

// ─── Application state ───────────────────────────────────────────────────────
struct AppState {
    Page     page         = Page::THERMO;
    HvacMode mode         = HvacMode::COOL;
    int      setTemp      = 74;
    float    currTemp     = 71.0f;
    float    humidity     = 68.0f;
    int      aqi          = 88;
    int      co2          = 620;
    int      filterDays   = 91;
    bool     dirty        = true;

    long     lastEnc      = 0;
    unsigned long lastSensorRead  = 0;
    unsigned long lastSimUpdate   = 0;

    // 96-slot ring buffer — one reading pushed every 3 s in sim
    // (swap to hourly in production for 4-day coverage)
    static constexpr int HIST_SIZE = 96;
    float  tempHistory[HIST_SIZE]  = {};
    int    histIdx                 = 0;
    int    histCount               = 0;
    int    histFrame               = 0;  // 0=1D 1=3D 2=7D 3=30D
};

// ─── Alert descriptor ────────────────────────────────────────────────────────
struct Alert {
    char     title[32];
    char     detail[40];
    uint16_t dotColor;
};
