#pragma once
#include <M5GFX.h>
#include "thermostat.h"

// Top-level draw call — clears canvas, routes to active page, pushes sprite
void drawFrame(M5Canvas &canvas, const AppState &s);

// Individual page renderers
void drawThermoPage  (M5Canvas &canvas, const AppState &s);
void drawHistoryPage (M5Canvas &canvas, const AppState &s);
void drawAlertsPage  (M5Canvas &canvas, const AppState &s);

// Shared helpers
void drawPageDots    (M5Canvas &canvas, const AppState &s);
void drawArcSegment  (M5Canvas &canvas, int cx, int cy, int r, int w,
                      float startDeg, float sweepDeg, uint16_t color);
