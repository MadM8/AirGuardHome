import 'package:flutter/material.dart';
import 'package:air_guard/pages/second.dart';
import 'package:air_guard/pages/third.dart';

// 
class SensorData {
  final double radon, temperature, humidity;
  final DateTime updatedAt;
  const SensorData({required this.radon, required this.temperature,
      required this.humidity, required this.updatedAt});
}

// 
class First extends StatefulWidget {
  const First({super.key});
  @override
  State<First> createState() => _FirstState();
}

class _FirstState extends State<First> {
  int _idx = 0;
  final _pages = const [Home(), Devices(), Thermostat()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('A I R G U A R D  H O M E',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF30759A),
      ),
      body: _pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Devices'),
          BottomNavigationBarItem(
              icon: Icon(Icons.device_thermostat_outlined), label: 'Thermostat'),
        ],
      ),
    );
  }
}

// Home page
class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace with a Firebase StreamBuilder when ready.
    final data = SensorData(
      radon: 42, temperature: 22.4, humidity: 55, updatedAt: DateTime.now());
    return _HomeView(data: data);
  }
}

// 
class _HomeView extends StatelessWidget {
  const _HomeView({required this.data});
  final SensorData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 191, 201, 209)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Living Room',
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 18, fontWeight: FontWeight.w700)),
              Text('Updated ${data.updatedAt.hour.toString().padLeft(2,'0')}:${data.updatedAt.minute.toString().padLeft(2,'0')}',
                  style: const TextStyle(color: Color(0xFF7EB8D4), fontSize: 12)),
            ]),
            _chip('Live', const Color(0xFF4ECDC4), leading: true),
          ]),
          const SizedBox(height: 20),

          // Radon card
          _card(
            accent: _radonColor(data.radon),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.air, color: _radonColor(data.radon), size: 18),
                const SizedBox(width: 6),
                Text('RADON', style: TextStyle(color: _radonColor(data.radon),
                    fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
                const Spacer(),
                _chip(_radonLabel(data.radon), _radonColor(data.radon)),
              ]),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(data.radon.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.white,
                        fontSize: 60, fontWeight: FontWeight.w300, height: 1)),
                const SizedBox(width: 8),
                const Padding(padding: EdgeInsets.only(bottom: 8),
                    child: Text('Bq/m³',
                        style: TextStyle(color: Colors.white54, fontSize: 15))),
              ]),
              const SizedBox(height: 14),
              _gauge(data.radon / 200, _radonColor(data.radon), thumb: true),
              const SizedBox(height: 6),
              const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Good', style: TextStyle(color: Color.fromARGB(255, 2, 168, 157), fontSize: 10)),
                  Text('Moderate', style: TextStyle(color: Color(0xFFFFD93D), fontSize: 10)),
                  Text('High', style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 10)),
                ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Temp + Humidity
          Row(children: [
            Expanded(child: _card(
              accent: const Color(0xFFFF9F43),
              child: _metricTile(Icons.thermostat_rounded, 'TEMPERATURE',
                  '${data.temperature.toStringAsFixed(1)}°C',
                  (data.temperature - 10) / 30, const Color(0xFFFF9F43), 'Normal range'),
            )),
            const SizedBox(width: 16),
            Expanded(child: _card(
              accent: _humidColor(data.humidity),
              child: _metricTile(Icons.water_drop_outlined, 'HUMIDITY',
                  '${data.humidity.toStringAsFixed(0)}%',
                  data.humidity / 100, _humidColor(data.humidity),
                  data.humidity >= 30 && data.humidity <= 60 ? 'Comfortable' : 'Out of range'),
            )),
          ]),
          const SizedBox(height: 16),

          // Summary banner
          _summaryBanner(data),
        ],
      ),
    );
  }

  //
  static Color _radonColor(double v) =>
      v < 100 ? const Color.fromARGB(255, 2, 168, 157) : v < 150 ? const Color(0xFFFFD93D) : const Color(0xFFFF6B6B);

  static String _radonLabel(double v) =>
      v < 100 ? 'Good' : v < 150 ? 'Moderate' : 'High';

  static Color _humidColor(double v) =>
      (v >= 30 && v <= 60) ? const Color.fromARGB(255, 2, 168, 157) : v > 60 ? const Color(0xFFFFD93D) : const Color(0xFFFF6B6B);

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
          Text(label, style: TextStyle(color: color,
              fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );

  static Widget _card({required Color accent, required Widget child}) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color.fromARGB(255, 153, 184, 207), Color.fromARGB(255, 136, 157, 179)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          border: Border.all(color: accent.withOpacity(0.35), width: 1.2),
          boxShadow: [BoxShadow(
              color: accent.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: child,
      );

  static Widget _gauge(double frac, Color color, {bool thumb = false}) {
    frac = frac.clamp(0.0, 1.0);
    return LayoutBuilder(builder: (_, box) => SizedBox(
      height: thumb ? 14 : 5,
      child: Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
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
        if (thumb)
          Positioned(
            left: (box.maxWidth * frac - 7).clamp(0, box.maxWidth - 14),
            top: 0,
            child: Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                color: color, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
              ),
            ),
          ),
      ]),
    ));
  }

  static Widget _metricTile(IconData icon, String label, String value,
      double frac, Color color, String sub) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color,
              fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
        ]),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(color: Colors.white,
            fontSize: 34, fontWeight: FontWeight.w300, height: 1)),
        const SizedBox(height: 10),
        _gauge(frac, color),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ]);

  static Widget _summaryBanner(SensorData d) {
    final bad = d.radon >= 150 || d.humidity > 70 || d.humidity < 30;
    final warn = d.radon >= 100 || d.humidity > 60;
    final color = bad ? const Color(0xFFFF6B6B) : warn ? const Color(0xFFFFD93D) : const Color.fromARGB(255, 2, 168, 157);
    final title = bad ? 'Action Needed' : warn ? 'Good' : 'Great';
    final msg = d.radon >= 150
        ? 'Radon is elevated — consider ventilating.'
        : d.humidity > 60 ? 'Humidity is high — a dehumidifier may help.'
        : d.humidity < 30 ? 'Air is dry — consider a humidifier.'
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
          decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(Icons.shield_outlined, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Overall: $title',
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(msg, style: const TextStyle(color: Color.fromARGB(153, 0, 0, 0), fontSize: 12, height: 1.4)),
        ])),
      ]),
    );
  }
}