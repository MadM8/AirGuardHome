import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Thermostat extends StatefulWidget {
  const Thermostat({super.key});

  @override
  State<Thermostat> createState() => _ThermostatState();
}

class _ThermostatState extends State<Thermostat>
    with SingleTickerProviderStateMixin {
  // Temperature state
  double _setTemp = 68.0;
  double _currentTemp = 72.0;
  final double _minTemp = 50.0;
  final double _maxTemp = 90.0;

  // Mode: 0=Heat, 1=Cool, 2=Auto, 3=Fan
  int _selectedMode = 0;

  // Preset: 0=Home, 1=Away, 2=Sleep
  int _selectedPreset = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Drag state for dial
  Offset? _dialCenter;
  double? _dragStartAngle;
  double? _dragStartTemp;

  final List<String> _modes = ['Heat', 'Cool', 'Auto', 'Fan'];
  final List<IconData> _modeIcons = [
    Icons.local_fire_department_rounded,
    Icons.ac_unit_rounded,
    Icons.autorenew_rounded,
    Icons.air_rounded,
  ];

  final List<String> _presets = ['Home', 'Away', 'Sleep'];
  final List<IconData> _presetIcons = [
    Icons.home_rounded,
    Icons.directions_walk_rounded,
    Icons.bedtime_rounded,
  ];
  final List<double> _presetTemps = [68.0, 62.0, 65.0];

  bool get _isHeating =>
      _selectedMode == 0 && _currentTemp < _setTemp;
  bool get _isCooling =>
      _selectedMode == 1 && _currentTemp > _setTemp;
  bool get _isActive => _isHeating || _isCooling;

  Color get _accentColor {
    if (_selectedMode == 1) return const Color(0xFF4FC3F7);
    if (_selectedMode == 3) return const Color(0xFF80CBC4);
    return const Color(0xFFFF7043);
  }

  Color get _accentColorDim {
    if (_selectedMode == 1) return const Color(0xFF4FC3F7).withOpacity(0.18);
    if (_selectedMode == 3) return const Color(0xFF80CBC4).withOpacity(0.18);
    return const Color(0xFFFF7043).withOpacity(0.18);
  }

  String get _statusText {
    if (_selectedMode == 3) return 'Fan only';
    if (_selectedMode == 2) return 'Auto';
    if (_isHeating) return 'Heating';
    if (_isCooling) return 'Cooling';
    return 'Standby';
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Convert temperature to arc angle (in radians)
  double _tempToAngle(double temp) {
    const startAngle = 140.0 * pi / 180.0;
    const sweepAngle = 260.0 * pi / 180.0;
    final t = (temp - _minTemp) / (_maxTemp - _minTemp);
    return startAngle + t * sweepAngle;
  }

  void _handleDialPanStart(DragStartDetails details, Size dialSize) {
    final center = Offset(dialSize.width / 2, dialSize.height / 2);
    _dialCenter = center;
    final local = details.localPosition;
    _dragStartAngle = atan2(local.dy - center.dy, local.dx - center.dx);
    _dragStartTemp = _setTemp;
  }

  void _handleDialPanUpdate(DragUpdateDetails details) {
    if (_dialCenter == null) return;
    final local = details.localPosition;
    final angle =
        atan2(local.dy - _dialCenter!.dy, local.dx - _dialCenter!.dx);
    final deltaAngle = angle - _dragStartAngle!;
    final tempDelta =
        deltaAngle / (260.0 * pi / 180.0) * (_maxTemp - _minTemp);
    final newTemp = (_dragStartTemp! + tempDelta).clamp(_minTemp, _maxTemp);
    final rounded = (newTemp * 2).round() / 2.0;
    if (rounded != _setTemp) {
      HapticFeedback.selectionClick();
      setState(() => _setTemp = rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F1117) : const Color(0xFFF5F5F7);
    final cardColor =
        isDark ? const Color(0xFF1C1E27) : Colors.white;
    final textPrimary =
        isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary =
        isDark ? const Color(0xFF9095A5) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ── Header ──────────────────────────────────
                _buildHeader(textPrimary, textSecondary, isDark),

                const SizedBox(height: 32),

                // ── Dial ────────────────────────────────────
                Center(child: _buildDial(textPrimary, textSecondary, isDark)),

                const SizedBox(height: 32),

                // ── Mode selector ───────────────────────────
                _buildModeSelector(cardColor, textPrimary, textSecondary, isDark),

                const SizedBox(height: 16),

                // ── Preset chips ────────────────────────────
                _buildPresetRow(cardColor, textPrimary, textSecondary),

                const SizedBox(height: 16),

                // ── Info cards ──────────────────────────────
                _buildInfoCards(cardColor, textPrimary, textSecondary),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(Color textPrimary, Color textSecondary, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Living Room',
              style: TextStyle(
                color: textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _isActive ? const Color(0xFF4CAF50) : textSecondary.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _statusText,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        _buildIconButton(
          icon: Icons.tune_rounded,
          isDark: isDark,
          textPrimary: textPrimary,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required bool isDark,
    required Color textPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1E27) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: textPrimary.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Icon(icon, color: textPrimary.withOpacity(0.7), size: 20),
      ),
    );
  }

  // ── Dial ──────────────────────────────────────────────────────────────────

  Widget _buildDial(Color textPrimary, Color textSecondary, bool isDark) {
    const dialSize = 260.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (d) =>
              _handleDialPanStart(d, const Size(dialSize, dialSize)),
          onPanUpdate: _handleDialPanUpdate,
          child: SizedBox(
            width: dialSize,
            height: dialSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow when active
                if (_isActive)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, _) => Container(
                      width: dialSize * _pulseAnimation.value,
                      height: dialSize * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _accentColor.withOpacity(0.15),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Custom painter for arc
                CustomPaint(
                  size: const Size(dialSize, dialSize),
                  painter: _DialPainter(
                    setTemp: _setTemp,
                    currentTemp: _currentTemp,
                    minTemp: _minTemp,
                    maxTemp: _maxTemp,
                    accentColor: _accentColor,
                    trackColor: isDark
                        ? const Color(0xFF2A2D38)
                        : const Color(0xFFE8E8EC),
                    isDark: isDark,
                  ),
                ),

                // Center content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current temp (large)
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: _currentTemp),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (_, val, __) => Text(
                        '${val.round()}°',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 56,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -2,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'set to ${_setTemp % 1 == 0 ? _setTemp.round() : _setTemp}°',
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusText,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // +/- quick buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _dialButton(
                          icon: Icons.remove,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _setTemp =
                                  (_setTemp - 1).clamp(_minTemp, _maxTemp);
                            });
                          },
                        ),
                        const SizedBox(width: 20),
                        _dialButton(
                          icon: Icons.add,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _setTemp =
                                  (_setTemp + 1).clamp(_minTemp, _maxTemp);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dialButton({
    required IconData icon,
    required bool isDark,
    required Color textPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2D38) : const Color(0xFFEEEEF2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: textPrimary.withOpacity(0.7)),
      ),
    );
  }

  // ── Mode selector ─────────────────────────────────────────────────────────

  Widget _buildModeSelector(
      Color cardColor, Color textPrimary, Color textSecondary, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: textPrimary.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: List.generate(_modes.length, (i) {
          final selected = _selectedMode == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedMode = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.all(5),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? _accentColorDim : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _modeIcons[i],
                      size: 20,
                      color: selected ? _accentColor : textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _modes[i],
                      style: TextStyle(
                        color: selected ? _accentColor : textSecondary,
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Preset row ────────────────────────────────────────────────────────────

  Widget _buildPresetRow(
      Color cardColor, Color textPrimary, Color textSecondary) {
    return Row(
      children: List.generate(_presets.length, (i) {
        final selected = _selectedPreset == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < _presets.length - 1 ? 10 : 0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedPreset = i;
                  _setTemp = _presetTemps[i];
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? _accentColorDim : cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? _accentColor.withOpacity(0.35)
                        : textPrimary.withOpacity(0.06),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _presetIcons[i],
                      size: 20,
                      color: selected ? _accentColor : textSecondary,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _presets[i],
                      style: TextStyle(
                        color: selected ? _accentColor : textSecondary,
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_presetTemps[i].round()}°',
                      style: TextStyle(
                        color: selected
                            ? _accentColor.withOpacity(0.8)
                            : textSecondary.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Info cards ────────────────────────────────────────────────────────────

  Widget _buildInfoCards(
      Color cardColor, Color textPrimary, Color textSecondary) {
    final cards = [
      _InfoCardData(
        icon: Icons.water_drop_outlined,
        label: 'Humidity',
        value: '45%',
        sub: 'Comfortable',
      ),
      _InfoCardData(
        icon: Icons.schedule_rounded,
        label: 'Next event',
        value: '7:00 AM',
        sub: 'Wake up',
      ),
      _InfoCardData(
        icon: Icons.bolt_rounded,
        label: 'Energy',
        value: '1.2 kW',
        sub: 'Today',
      ),
    ];

    return Row(
      children: cards.asMap().entries.map((e) {
        final i = e.key;
        final data = e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < cards.length - 1 ? 10 : 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: textPrimary.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(data.icon,
                      size: 18,
                      color: _accentColor.withOpacity(0.85)),
                  const SizedBox(height: 8),
                  Text(
                    data.value,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.label,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    data.sub,
                    style: TextStyle(
                      color: textSecondary.withOpacity(0.55),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _InfoCardData {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  const _InfoCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });
}

// ── Custom dial painter ───────────────────────────────────────────────────────

class _DialPainter extends CustomPainter {
  final double setTemp;
  final double currentTemp;
  final double minTemp;
  final double maxTemp;
  final Color accentColor;
  final Color trackColor;
  final bool isDark;

  const _DialPainter({
    required this.setTemp,
    required this.currentTemp,
    required this.minTemp,
    required this.maxTemp,
    required this.accentColor,
    required this.trackColor,
    required this.isDark,
  });

  static const double _startDeg = 140.0;
  static const double _sweepDeg = 260.0;

  double _tempToSweep(double temp) {
    final t = (temp - minTemp) / (maxTemp - minTemp);
    return t * _sweepDeg * pi / 180.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 18;
    const strokeWidth = 14.0;

    final startRad = _startDeg * pi / 180.0;

    // ── Background track ──
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startRad,
      _sweepDeg * pi / 180.0,
      false,
      trackPaint,
    );

    // ── Filled arc (set temp) ──
    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startRad,
        endAngle: startRad + _sweepDeg * pi / 180.0,
        colors: [
          accentColor.withOpacity(0.5),
          accentColor,
        ],
        tileMode: TileMode.clamp,
        transform: GradientRotation(startRad),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final setTempSweep = _tempToSweep(setTemp);
    if (setTempSweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startRad,
        setTempSweep,
        false,
        arcPaint,
      );
    }

    // ── Current temp tick ──
    final currentAngle = startRad + _tempToSweep(currentTemp);
    final tickOuter = Offset(
      center.dx + (radius + strokeWidth / 2 + 4) * cos(currentAngle),
      center.dy + (radius + strokeWidth / 2 + 4) * sin(currentAngle),
    );
    final tickInner = Offset(
      center.dx + (radius - strokeWidth / 2 - 4) * cos(currentAngle),
      center.dy + (radius - strokeWidth / 2 - 4) * sin(currentAngle),
    );

    final tickPaint = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF1A1A2E)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(tickInner, tickOuter, tickPaint);

    // ── Tick marks ──
    final tickMarkPaint = Paint()
      ..color = trackColor.withOpacity(isDark ? 0.6 : 0.9)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    const int tickCount = 40;
    for (int i = 0; i <= tickCount; i++) {
      final angle = startRad + (i / tickCount) * _sweepDeg * pi / 180.0;
      final isMajor = i % 5 == 0;
      final outerR = radius + strokeWidth / 2 + (isMajor ? 10 : 6);
      final innerR = radius + strokeWidth / 2 + 2;

      canvas.drawLine(
        Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle)),
        Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle)),
        tickMarkPaint,
      );
    }

    // ── Min/Max labels ──
    // These are painted as text using TextPainter
    _drawTickLabel(canvas, center, radius, startRad, '${minTemp.round()}°',
        isDark ? Colors.white38 : Colors.black26, -16);
    _drawTickLabel(
        canvas,
        center,
        radius,
        startRad + _sweepDeg * pi / 180.0,
        '${maxTemp.round()}°',
        isDark ? Colors.white38 : Colors.black26,
        16);
  }

  void _drawTickLabel(Canvas canvas, Offset center, double radius,
      double angle, String text, Color color, double xOffset) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelRadius = radius + 30;
    final pos = Offset(
      center.dx + labelRadius * cos(angle) - textPainter.width / 2 + xOffset,
      center.dy + labelRadius * sin(angle) - textPainter.height / 2,
    );
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.setTemp != setTemp ||
      old.currentTemp != currentTemp ||
      old.accentColor != accentColor;
}