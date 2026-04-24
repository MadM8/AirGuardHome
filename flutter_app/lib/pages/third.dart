import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';

class Thermostat extends StatefulWidget {
  const Thermostat({super.key});
  @override
  State<Thermostat> createState() => _ThermostatState();
}

class _ThermostatState extends State<Thermostat>
    with SingleTickerProviderStateMixin {
  double _setTemp = 68;
  double _currentTemp = 72;   // will be overwritten by Firebase
  double _currentHumidity = 45; // will be overwritten by Firebase
  bool _loadingFirebase = true;

  int _mode = 0, _preset = 0;

  final _modes      = ['Heat', 'Cool', 'Auto', 'Fan'];
  final _modeIcons  = [Icons.local_fire_department_rounded, Icons.ac_unit_rounded, Icons.autorenew_rounded, Icons.air_rounded];
  final _presets      = ['Home', 'Sleep'];
  final _presetIcons  = [Icons.home_rounded, Icons.bedtime_rounded];
  final _presetTemps  = [68.0, 65.0];

  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat(reverse: true);
  late final Animation<double> _pulseAnim =
      Tween(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

  // Firebase
  late final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref('/airguard');
  late final Stream<DatabaseEvent> _sensorStream = _dbRef.onValue;

  Offset? _dialCenter;
  double? _dragStartAngle, _dragStartTemp;

  bool get _isActive =>
      (_mode == 0 && _currentTemp < _setTemp) ||
      (_mode == 1 && _currentTemp > _setTemp);

  Color get _accent => switch (_mode) {
    1 => const Color(0xFF4FC3F7),
    3 => const Color(0xFF80CBC4),
    _ => const Color(0xFFFF7043),
  };

  String get _status => switch (_mode) {
    3 => 'Fan only',
    2 => 'Auto',
    0 => _currentTemp < _setTemp ? 'Heating' : 'Standby',
    _ => _currentTemp > _setTemp ? 'Cooling' : 'Standby',
  };

  String get _humidityLabel {
    if (_currentHumidity < 30) return 'Too Dry';
    if (_currentHumidity > 60) return 'Too Humid';
    return 'Comfortable';
  }

  // Convert °C from Firebase to °F for the thermostat dial
  double _celsiusToFahrenheit(double c) => c * 9 / 5 + 32;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails d, double size) {
    final c = Offset(size / 2, size / 2);
    _dialCenter = c;
    _dragStartAngle =
        atan2(d.localPosition.dy - c.dy, d.localPosition.dx - c.dx);
    _dragStartTemp = _setTemp;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_dialCenter == null) return;
    final angle = atan2(
        d.localPosition.dy - _dialCenter!.dy,
        d.localPosition.dx - _dialCenter!.dx);
    final newTemp =
        ((_dragStartTemp! + (angle - _dragStartAngle!) / (260 * pi / 180) * 40)
                    .clamp(50, 90) *
                2)
            .round() /
        2.0;
    if (newTemp != _setTemp) {
      HapticFeedback.selectionClick();
      setState(() => _setTemp = newTemp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg   = dark ? const Color(0xFF0F1117) : const Color(0xFFF5F5F7);
    final card = dark ? const Color(0xFF1C1E27) : Colors.white;
    final tp   = dark ? Colors.white : const Color(0xFF1A1A2E);
    final ts   = dark ? const Color(0xFF9095A5) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bg,
      body: StreamBuilder<DatabaseEvent>(
        stream: _sensorStream,
        builder: (context, snapshot) {
          // Update local state when new Firebase data arrives
          if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
            final map = Map<dynamic, dynamic>.from(
                snapshot.data!.snapshot.value as Map);
            final tempC = (map['temperature'] ?? 0).toDouble();
            final humidity = (map['humidity'] ?? 45).toDouble();

            // Schedule state update after build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _currentTemp = _celsiusToFahrenheit(tempC);
                  _currentHumidity = humidity;
                  _loadingFirebase = false;
                });
              }
            });
          }

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                const SizedBox(height: 24),
                _header(tp, ts, dark),
                const SizedBox(height: 32),

                // Show spinner on first load, dial after
                if (_loadingFirebase &&
                    snapshot.connectionState == ConnectionState.waiting)
                  SizedBox(
                    height: 260,
                    child: Center(
                      child: CircularProgressIndicator(color: _accent),
                    ),
                  )
                else
                  _dial(tp, ts, dark),

                const SizedBox(height: 32),
                _modeRow(card, tp, ts),
                const SizedBox(height: 16),
                _presetRow(card, tp, ts),
                const SizedBox(height: 16),
                _humidityCard(card, tp, ts),
                const SizedBox(height: 24),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _header(Color tp, Color ts, bool dark) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Living Room',
              style: TextStyle(
                  color: tp,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Row(children: [
            AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isActive
                        ? const Color(0xFF4CAF50)
                        : ts.withOpacity(0.4))),
            const SizedBox(width: 6),
            Text(_status,
                style: TextStyle(
                    color: ts, fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
        ]),
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: dark ? const Color(0xFF1C1E27) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tp.withOpacity(0.08))),
            child:
                Icon(Icons.tune_rounded, color: tp.withOpacity(0.7), size: 20),
          ),
        ),
      ]);

  // ── Dial ────────────────────────────────────────────────────────────────

  Widget _dial(Color tp, Color ts, bool dark) {
    const s = 260.0;
    return GestureDetector(
      onPanStart: (d) => _onPanStart(d, s),
      onPanUpdate: _onPanUpdate,
      child: SizedBox(
          width: s,
          height: s,
          child: Stack(alignment: Alignment.center, children: [
            if (_isActive)
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  width: s * _pulseAnim.value,
                  height: s * _pulseAnim.value,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: _accent.withOpacity(0.15),
                            blurRadius: 40,
                            spreadRadius: 10)
                      ]),
                ),
              ),
            CustomPaint(
                size: const Size(s, s),
                painter:
                    _DialPainter(_setTemp, _currentTemp, _accent, dark)),
            Column(mainAxisSize: MainAxisSize.min, children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: _currentTemp),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (_, v, __) => Text('${v.round()}°F',
                    style: TextStyle(
                        color: tp,
                        fontSize: 52,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -2,
                        height: 1)),
              ),
              const SizedBox(height: 4),
              Text(
                  'set to ${_setTemp % 1 == 0 ? _setTemp.round() : _setTemp}°',
                  style: TextStyle(
                      color: _accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(_status, style: TextStyle(color: ts, fontSize: 12)),
              const SizedBox(height: 14),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _dialBtn(Icons.remove, tp, dark, () {
                  HapticFeedback.selectionClick();
                  setState(() => _setTemp = (_setTemp - 1).clamp(50, 90));
                }),
                const SizedBox(width: 20),
                _dialBtn(Icons.add, tp, dark, () {
                  HapticFeedback.selectionClick();
                  setState(() => _setTemp = (_setTemp + 1).clamp(50, 90));
                }),
              ]),
            ]),
          ])),
    );
  }

  Widget _dialBtn(
          IconData icon, Color tp, bool dark, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: dark
                  ? const Color(0xFF2A2D38)
                  : const Color(0xFFEEEEF2),
              shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: tp.withOpacity(0.7)),
        ),
      );

  // ── Mode row ─────────────────────────────────────────────────────────────

  Widget _modeRow(Color card, Color tp, Color ts) => Container(
        decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tp.withOpacity(0.06))),
        child: Row(
            children: List.generate(_modes.length, (i) {
          final sel = _mode == i;
          return Expanded(
              child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _mode = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  color: sel ? _accent.withOpacity(0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(11)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(_modeIcons[i], size: 20, color: sel ? _accent : ts),
                const SizedBox(height: 4),
                Text(_modes[i],
                    style: TextStyle(
                        color: sel ? _accent : ts,
                        fontSize: 11,
                        fontWeight:
                            sel ? FontWeight.w600 : FontWeight.w400)),
              ]),
            ),
          ));
        })),
      );

  // ── Preset row ────────────────────────────────────────────────────────────

  Widget _presetRow(Color card, Color tp, Color ts) => Row(
        children: List.generate(
            _presets.length,
            (i) => Expanded(
                    child: Padding(
                  padding: EdgeInsets.only(right: i == 0 ? 10 : 0),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _preset = i;
                        _setTemp = _presetTemps[i];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _preset == i
                            ? _accent.withOpacity(0.18)
                            : card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _preset == i
                                ? _accent.withOpacity(0.35)
                                : tp.withOpacity(0.06)),
                      ),
                      child: Column(children: [
                        Icon(_presetIcons[i],
                            size: 20,
                            color: _preset == i ? _accent : ts),
                        const SizedBox(height: 5),
                        Text(_presets[i],
                            style: TextStyle(
                                color: _preset == i ? _accent : ts,
                                fontSize: 12,
                                fontWeight: _preset == i
                                    ? FontWeight.w600
                                    : FontWeight.w400)),
                        const SizedBox(height: 2),
                        Text('${_presetTemps[i].round()}°',
                            style: TextStyle(
                                color: (_preset == i ? _accent : ts)
                                    .withOpacity(0.7),
                                fontSize: 11)),
                      ]),
                    ),
                  ),
                ))),
      );

  // ── Humidity card — now live from Firebase ────────────────────────────────

  Widget _humidityCard(Color card, Color tp, Color ts) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tp.withOpacity(0.06))),
        child: Row(children: [
          Icon(Icons.water_drop_outlined, size: 20, color: _accent),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_currentHumidity.toStringAsFixed(1)}%',
                style: TextStyle(
                    color: tp,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            Text('Humidity · $_humidityLabel',
                style: TextStyle(color: ts, fontSize: 12)),
          ]),
          const Spacer(),
          // Live indicator
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.circle, color: Color(0xFF4CAF50), size: 7),
              SizedBox(width: 4),
              Text('Live',
                  style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      );
}

// ── Dial Painter (unchanged) ─────────────────────────────────────────────────

class _DialPainter extends CustomPainter {
  final double setTemp, currentTemp;
  final Color accent;
  final bool dark;
  const _DialPainter(this.setTemp, this.currentTemp, this.accent, this.dark);

  static const _start = 140.0 * pi / 180.0;
  static const _sweep = 260.0 * pi / 180.0;
  double _frac(double t) => (t - 50) / 40;

  @override
  void paint(Canvas canvas, Size size) {
    final c  = Offset(size.width / 2, size.height / 2);
    final r  = size.width / 2 - 18;
    const sw = 14.0;

    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), _start, _sweep, false,
        Paint()
          ..color = dark
              ? const Color(0xFF2A2D38)
              : const Color(0xFFE8E8EC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round);

    final sweep = _frac(setTemp) * _sweep;
    if (sweep > 0)
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r), _start, sweep, false,
          Paint()
            ..shader = SweepGradient(
                    startAngle: _start,
                    endAngle: _start + _sweep,
                    colors: [accent.withOpacity(0.5), accent],
                    transform: GradientRotation(_start))
                .createShader(Rect.fromCircle(center: c, radius: r))
            ..style = PaintingStyle.stroke
            ..strokeWidth = sw
            ..strokeCap = StrokeCap.round);

    final a = _start + _frac(currentTemp) * _sweep;
    canvas.drawLine(
        Offset(c.dx + (r - sw / 2 - 4) * cos(a),
            c.dy + (r - sw / 2 - 4) * sin(a)),
        Offset(c.dx + (r + sw / 2 + 4) * cos(a),
            c.dy + (r + sw / 2 + 4) * sin(a)),
        Paint()
          ..color = dark ? Colors.white : const Color(0xFF1A1A2E)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round);

    final tickPaint = Paint()
      ..color =
          (dark ? Colors.white : Colors.black).withOpacity(0.15)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i <= 40; i++) {
      final ta    = _start + (i / 40) * _sweep;
      final outer = r + sw / 2 + (i % 5 == 0 ? 10 : 6);
      canvas.drawLine(
          Offset(c.dx + (r + sw / 2 + 2) * cos(ta),
              c.dy + (r + sw / 2 + 2) * sin(ta)),
          Offset(c.dx + outer * cos(ta), c.dy + outer * sin(ta)),
          tickPaint);
    }
  }

  @override
  bool shouldRepaint(_DialPainter o) =>
      o.setTemp != setTemp ||
      o.currentTemp != currentTemp ||
      o.accent != accent;
}