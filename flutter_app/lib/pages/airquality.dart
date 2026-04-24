import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

// ── Data Model ───────────────────────────────────────────────────────────────
// SGP30    → eco2 (ppm), tvoc (ppb)
// PMSA003I → pm10 (PM1.0), pm25 (PM2.5), pm100 (PM10) µg/m³ standard
//            particles_03/05/10/25/50/100 per 0.1L air
class AirQualityData {
  final double eco2;        // SGP30 — eCO2, 400–60,000 ppm
  final double tvoc;        // SGP30 — TVOC, 0–60,000 ppb
  final double pm10;        // PMSA003I — PM1.0 µg/m³
  final double pm25;        // PMSA003I — PM2.5 µg/m³
  final double pm100;       // PMSA003I — PM10  µg/m³
  final int particles03;    // PMSA003I — particles ≥0.3µm per 0.1L
  final int particles05;
  final int particles10;
  final int particles25;
  final int particles50;
  final int particles100;
  final DateTime updatedAt;

  const AirQualityData({
    required this.eco2,
    required this.tvoc,
    required this.pm10,
    required this.pm25,
    required this.pm100,
    required this.particles03,
    required this.particles05,
    required this.particles10,
    required this.particles25,
    required this.particles50,
    required this.particles100,
    required this.updatedAt,
  });
}

// ── Page Entry Point ─────────────────────────────────────────────────────────
class AirQuality extends StatelessWidget {
  const AirQuality({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('/airguard').onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sensors_off, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text('Waiting for air quality data...',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        final map = Map<dynamic, dynamic>.from(
            snapshot.data!.snapshot.value as Map);

        final data = AirQualityData(
          // SGP30 fields
          eco2:         (map['eco2']          ?? 400).toDouble(),
          tvoc:         (map['tvoc']          ?? 0).toDouble(),
          // PMSA003I concentration fields
          pm10:         (map['pm10']          ?? 0).toDouble(),   // PM1.0
          pm25:         (map['pm25']          ?? 0).toDouble(),   // PM2.5
          pm100:        (map['pm100']         ?? 0).toDouble(),   // PM10
          // PMSA003I particle count fields
          particles03:  (map['particles_03']  ?? 0).toInt(),
          particles05:  (map['particles_05']  ?? 0).toInt(),
          particles10:  (map['particles_10']  ?? 0).toInt(),
          particles25:  (map['particles_25']  ?? 0).toInt(),
          particles50:  (map['particles_50']  ?? 0).toInt(),
          particles100: (map['particles_100'] ?? 0).toInt(),
          updatedAt: DateTime.now(),
        );

        return _AirQualityView(data: data);
      },
    );
  }
}

// ── Main View ────────────────────────────────────────────────────────────────
class _AirQualityView extends StatelessWidget {
  const _AirQualityView({required this.data});
  final AirQualityData data;

  @override
  Widget build(BuildContext context) {
    final aqi      = _calcAQI(data.pm25);
    final aqiColor = _aqiColor(aqi);
    final aqiLabel = _aqiLabel(aqi);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 255, 255, 255),
            Color.fromARGB(255, 191, 201, 209),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Header ──
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Air Quality',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              Text(
                  'Updated ${data.updatedAt.hour.toString().padLeft(2, '0')}:${data.updatedAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Color(0xFF7EB8D4), fontSize: 12)),
            ]),
            _chip('Live', const Color(0xFF4ECDC4), leading: true),
          ]),
          const SizedBox(height: 20),

          // ── AQI Overview ──
          _aqiCard(aqi, aqiColor, aqiLabel),
          const SizedBox(height: 16),

          // ── Particulate Matter ──
          _sectionLabel('PARTICULATE MATTER', 'PMSA003I'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _pmCard(
              label: 'PM1.0', value: data.pm10, maxVal: 75,
              color: _pm10Color(data.pm10), status: _pm10Label(data.pm10),
              tip: 'Ultrafine particles',
            )),
            const SizedBox(width: 12),
            Expanded(child: _pmCard(
              label: 'PM2.5', value: data.pm25, maxVal: 75,
              color: _pm25Color(data.pm25), status: _pm25Label(data.pm25),
              tip: 'Fine particles',
            )),
            const SizedBox(width: 12),
            Expanded(child: _pmCard(
              label: 'PM10', value: data.pm100, maxVal: 150,
              color: _pm100Color(data.pm100), status: _pm100Label(data.pm100),
              tip: 'Coarse particles',
            )),
          ]),
          const SizedBox(height: 16),

          // ── Particle Count Breakdown ──
          _particleCountCard(data),
          const SizedBox(height: 16),

          // ── SGP30 Gas Sensors ──
          _sectionLabel('GAS SENSORS', 'SGP30'),
          const SizedBox(height: 10),
          _eco2Card(data.eco2),
          const SizedBox(height: 16),
          _tvocCard(data.tvoc),
          const SizedBox(height: 16),

          // ── Summary Banner ──
          _summaryBanner(data, aqi),
        ],
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────
  static Widget _sectionLabel(String title, String sensor) =>
      Row(children: [
        Text(title,
            style: const TextStyle(
                color: Colors.black54, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF30759A).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(sensor,
              style: const TextStyle(
                  color: Color(0xFF30759A), fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 1)),
        ),
      ]);

  // ── AQI Card ──────────────────────────────────────────────────────────────
  static Widget _aqiCard(int aqi, Color color, String label) =>
      _baseCard(
        accent: color,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.air_outlined, color: color, size: 18),
            const SizedBox(width: 6),
            Text('AIR QUALITY INDEX',
                style: TextStyle(color: color, fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 2)),
            const Spacer(),
            _chip(label, color),
          ]),
          const SizedBox(height: 4),
          const Text('Based on PM2.5 — US EPA formula',
              style: TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(aqi.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 60,
                    fontWeight: FontWeight.w300, height: 1)),
            const SizedBox(width: 8),
            const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('AQI',
                    style: TextStyle(color: Colors.white54, fontSize: 15))),
          ]),
          const SizedBox(height: 14),
          _aqiScaleBar(aqi),
          const SizedBox(height: 6),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Good',     style: TextStyle(color: Color(0xFF4ECDC4), fontSize: 10)),
                Text('Moderate', style: TextStyle(color: Color(0xFFFFD93D), fontSize: 10)),
                Text('Unhealthy',style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 10)),
              ]),
        ]),
      );

  static Widget _aqiScaleBar(int aqi) {
    final frac  = (aqi / 300).clamp(0.0, 1.0);
    final color = _aqiColor(aqi);
    return LayoutBuilder(builder: (_, box) => SizedBox(
      height: 14,
      child: Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                Color(0xFF4ECDC4), Color(0xFFFFD93D), Color(0xFFFF6B6B),
              ]),
            ),
          ),
        ),
        Positioned(
          left: (box.maxWidth * frac - 7).clamp(0, box.maxWidth - 14),
          top: 0,
          child: Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5),
              boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
            ),
          ),
        ),
      ]),
    ));
  }

  // ── PM small card ─────────────────────────────────────────────────────────
  static Widget _pmCard({
    required String label, required double value, required double maxVal,
    required Color color,  required String status, required String tip,
  }) =>
      _baseCard(
        accent: color,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: color, fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          Text(tip, style: const TextStyle(color: Colors.white38, fontSize: 9)),
          const SizedBox(height: 10),
          Text(value.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.w300, height: 1)),
          const Text('µg/m³',
              style: TextStyle(color: Colors.white54, fontSize: 9)),
          const SizedBox(height: 8),
          _gauge((value / maxVal).clamp(0.0, 1.0), color),
          const SizedBox(height: 5),
          Text(status, style: TextStyle(color: color, fontSize: 9)),
        ]),
      );

  // ── Particle Count Bar Chart ───────────────────────────────────────────────
  static Widget _particleCountCard(AirQualityData d) {
    final bins = [
      ('≥0.3µm', d.particles03),
      ('≥0.5µm', d.particles05),
      ('≥1.0µm', d.particles10),
      ('≥2.5µm', d.particles25),
      ('≥5.0µm', d.particles50),
      ('≥10µm',  d.particles100),
    ];
    final maxCount = bins.map((b) => b.$2).fold(1, (a, b) => a > b ? a : b);

    return _baseCard(
      accent: const Color(0xFF7EB8D4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.scatter_plot_outlined,
              color: Color(0xFF7EB8D4), size: 16),
          const SizedBox(width: 6),
          const Text('PARTICLE COUNTS',
              style: TextStyle(color: Color.fromARGB(255, 18, 79, 110), fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const Spacer(),
          const Text('per 0.1L air',
              style: TextStyle(color: Colors.white38, fontSize: 10)),
        ]),
        const SizedBox(height: 16),
        ...bins.map((bin) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            SizedBox(width: 46,
                child: Text(bin.$1,
                    style: const TextStyle(color: Colors.white60, fontSize: 10))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(height: 8,
                  child: Stack(children: [
                    Container(color: Colors.white10),
                    FractionallySizedBox(
                      widthFactor: (bin.$2 / maxCount).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF7EB8D4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(width: 42,
                child: Text(bin.$2.toString(),
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.white70, fontSize: 10,
                        fontWeight: FontWeight.w600))),
          ]),
        )),
      ]),
    );
  }

  // ── eCO2 Card ─────────────────────────────────────────────────────────────
  static Widget _eco2Card(double eco2) {
    final color = _eco2Color(eco2);
    return _baseCard(
      accent: color,
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.cloud_outlined, color: color, size: 16),
            const SizedBox(width: 5),
            Text('eCO₂', style: TextStyle(color: color, fontSize: 10,
                fontWeight: FontWeight.w700, letterSpacing: 1.4)),
            const SizedBox(width: 6),
            const Text('Equivalent CO₂  ·  SGP30',
                style: TextStyle(color: Colors.white38, fontSize: 10)),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(eco2.toStringAsFixed(0),
                style: const TextStyle(color: Colors.white, fontSize: 38,
                    fontWeight: FontWeight.w300, height: 1)),
            const SizedBox(width: 6),
            const Padding(padding: EdgeInsets.only(bottom: 5),
                child: Text('ppm',
                    style: TextStyle(color: Colors.white54, fontSize: 13))),
          ]),
          const SizedBox(height: 10),
          _gauge(((eco2 - 400) / 1600).clamp(0.0, 1.0), color),
          const SizedBox(height: 6),
          Text(_eco2Label(eco2), style: TextStyle(color: color, fontSize: 11)),
          const SizedBox(height: 4),
          const Text('Calculated from Hydrogen (H₂).',
              style: TextStyle(color: Colors.white30, fontSize: 9)),
        ])),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _levelBadge('400',  'Baseline', const Color(0xFF4ECDC4)),
          const SizedBox(height: 8),
          _levelBadge('1000', 'Drowsy',   const Color(0xFFFFD93D)),
          const SizedBox(height: 8),
          _levelBadge('2000+','Harmful',  const Color(0xFFFF6B6B)),
        ]),
      ]),
    );
  }

  // ── TVOC Card ─────────────────────────────────────────────────────────────
  static Widget _tvocCard(double tvoc) {
    final color = _tvocColor(tvoc);
    return _baseCard(
      accent: color,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.science_outlined, color: color, size: 16),
          const SizedBox(width: 5),
          Text('TVOC', style: TextStyle(color: color, fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 1.4)),
          const SizedBox(width: 6),
          const Text('Total Volatile Organics  ·  SGP30',
              style: TextStyle(color: Colors.white38, fontSize: 10)),
          const Spacer(),
          _chip(_tvocLabel(tvoc), color),
        ]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(tvoc.toStringAsFixed(0),
              style: const TextStyle(color: Colors.white, fontSize: 38,
                  fontWeight: FontWeight.w300, height: 1)),
          const SizedBox(width: 6),
          const Padding(padding: EdgeInsets.only(bottom: 5),
              child: Text('ppb',
                  style: TextStyle(color: Colors.white54, fontSize: 13))),
        ]),
        const SizedBox(height: 10),
        _gauge((tvoc / 500).clamp(0.0, 1.0), color),
        const SizedBox(height: 6),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Clean  <220 ppb',  style: TextStyle(color: Color(0xFF4ECDC4), fontSize: 10)),
              Text('Moderate',         style: TextStyle(color: Color(0xFFFFD93D), fontSize: 10)),
              Text('>660 ppb  Poor',   style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 10)),
            ]),
      ]),
    );
  }

  // ── Summary Banner ────────────────────────────────────────────────────────
  static Widget _summaryBanner(AirQualityData d, int aqi) {
    final bad  = aqi > 150 || d.eco2 > 1500 || d.tvoc > 660;
    final warn = aqi > 100 || d.eco2 > 1000 || d.tvoc > 220;
    final color = bad
        ? const Color(0xFFFF6B6B)
        : warn ? const Color(0xFFFFD93D)
               : const Color.fromARGB(255, 2, 168, 157);
    final title = bad ? 'Action Needed' : warn ? 'Monitor Closely' : 'All Clear';
    final msg = d.tvoc > 660
        ? 'TVOC is high — improve ventilation.'
        : d.eco2 > 1500
            ? 'eCO₂ elevated — open windows to ventilate.'
            : aqi > 150
                ? 'Particulate levels are unhealthy — consider an air purifier.'
                : d.pm25 > 35
                    ? 'PM2.5 is elevated — reduce indoor particle sources.'
                    : 'All sensors are within healthy ranges.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: color.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(Icons.shield_outlined, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Overall: $title',
                  style: TextStyle(color: color, fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(msg,
                  style: const TextStyle(
                      color: Color.fromARGB(153, 0, 0, 0),
                      fontSize: 12, height: 1.4)),
            ])),
      ]),
    );
  }

  // ── Shared Card Shell ─────────────────────────────────────────────────────
  static Widget _baseCard({
    required Color accent, required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) =>
      Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 153, 184, 207),
              Color.fromARGB(255, 136, 157, 179),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: accent.withOpacity(0.35), width: 1.2),
          boxShadow: [
            BoxShadow(color: accent.withOpacity(0.12),
                blurRadius: 20, offset: const Offset(0, 6))
          ],
        ),
        child: child,
      );

  static Widget _chip(String label, Color color, {bool leading = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (leading) ...[
            Icon(Icons.circle, color: color, size: 7),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(color: color, fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  static Widget _gauge(double frac, Color color) {
    frac = frac.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 5,
        child: Stack(children: [
          Container(color: Colors.white10),
          FractionallySizedBox(
            widthFactor: frac,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  static Widget _levelBadge(String value, String label, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(value, style: TextStyle(color: color, fontSize: 12,
            fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ]);

  // ── EPA PM2.5 AQI ─────────────────────────────────────────────────────────
  static int _calcAQI(double pm25) {
    const bp = [
      [0.0,  12.0,   0,  50],
      [12.1, 35.4,  51, 100],
      [35.5, 55.4, 101, 150],
      [55.5,150.4, 151, 200],
      [150.5,250.4,201, 300],
    ];
    for (final b in bp) {
      if (pm25 <= b[1]) {
        return ((b[3] - b[2]) / (b[1] - b[0]) * (pm25 - b[0]) + b[2])
            .round().clamp(0, 500);
      }
    }
    return 300;
  }

  // ── Color / Label helpers ─────────────────────────────────────────────────
  static Color _aqiColor(int v)   => v < 51 ? const Color.fromARGB(255, 2, 168, 157) : v < 101 ? const Color(0xFFFFD93D) : const Color(0xFFFF6B6B);
  static String _aqiLabel(int v)  => v < 51 ? 'Good' : v < 101 ? 'Moderate' : v < 151 ? 'Sensitive Groups' : 'Unhealthy';

  static Color  _pm10Color(double v)  => v < 12  ? const Color.fromARGB(255, 2, 168, 157) : v < 35  ? const Color(0xFFFFD93D) : const Color(0xFFFF6B6B);
  static String _pm10Label(double v)  => v < 12  ? 'Good' : v < 35  ? 'Moderate' : 'High';

  static Color  _pm25Color(double v)  => v < 12  ? const Color.fromARGB(255, 2, 168, 157) : v < 35.4? const Color(0xFFFFD93D) : const Color(0xFFFF6B6B);
  static String _pm25Label(double v)  => v < 12  ? 'Good' : v < 35.4? 'Moderate' : 'High';

  static Color  _pm100Color(double v) => v < 54  ? const Color.fromARGB(255, 2, 168, 157) : v < 154 ? const Color(0xFFFFD93D) : const Color(0xFFFF6B6B);
  static String _pm100Label(double v) => v < 54  ? 'Good' : v < 154 ? 'Moderate' : 'High';

  static Color  _eco2Color(double v)  => v < 1000 ? const Color.fromARGB(255, 2, 168, 157) : v < 2000 ? const Color(0xFFFFD93D) : const Color(0xFFFF6B6B);
  static String _eco2Label(double v)  => v < 800  ? 'Good' : v < 1000 ? 'Acceptable' : v < 2000 ? 'Ventilate soon' : 'Harmful';

  static Color  _tvocColor(double v)  => v < 220 ? const Color.fromARGB(255, 2, 168, 157) : v < 660 ? const Color(0xFFFFD93D) : const Color(0xFFFF6B6B);
  static String _tvocLabel(double v)  => v < 220 ? 'Good' : v < 660 ? 'Moderate' : 'High';
}