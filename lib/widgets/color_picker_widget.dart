import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A self-contained HSV colour picker with a hue ring, saturation/value square,
/// and a hex-code text field.  No external dependencies.
class ColorPickerWidget extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerWidget({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  late double _hue; // 0..360
  late double _saturation; // 0..1
  late double _value; // 0..1
  late TextEditingController _hexController;
  bool _updatingFromHex = false;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
    _hexController = TextEditingController(text: _colorToHex6(widget.initialColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color get _currentColor =>
      HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();

  String _colorToHex6(Color c) {
    return c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  }

  void _notifyChange() {
    final color = _currentColor;
    if (!_updatingFromHex) {
      _hexController.text = _colorToHex6(color);
    }
    widget.onColorChanged(color);
  }

  void _onHexSubmitted(String text) {
    final hex = text.replaceAll('#', '').trim();
    if (hex.length == 6 && RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hex)) {
      final color = Color(int.parse('FF$hex', radix: 16));
      final hsv = HSVColor.fromColor(color);
      _updatingFromHex = true;
      setState(() {
        _hue = hsv.hue;
        _saturation = hsv.saturation;
        _value = hsv.value;
      });
      widget.onColorChanged(color);
      _updatingFromHex = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ---- HSV Wheel (hue ring + SV square) ----
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Hue ring
              _HueRing(
                hue: _hue,
                onHueChanged: (h) {
                  setState(() => _hue = h);
                  _notifyChange();
                },
              ),
              // SV square inside the ring
              _SVSquare(
                hue: _hue,
                saturation: _saturation,
                value: _value,
                onChanged: (s, v) {
                  setState(() {
                    _saturation = s;
                    _value = v;
                  });
                  _notifyChange();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ---- Hex input + preview ----
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _currentColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(80),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 130,
              child: TextField(
                controller: _hexController,
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  prefixText: '#',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: _onHexSubmitted,
                onSubmitted: _onHexSubmitted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hue Ring
// ─────────────────────────────────────────────────────────────────────────────

class _HueRing extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onHueChanged;

  const _HueRing({required this.hue, required this.onHueChanged});

  static const double _outerRadius = 110;
  static const double _ringWidth = 22;

  void _handleInteraction(Offset localPosition) {
    final center = const Offset(_outerRadius, _outerRadius);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final angle = (atan2(dy, dx) * 180 / pi + 360) % 360;
    onHueChanged(angle);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _handleInteraction(d.localPosition),
      onPanUpdate: (d) => _handleInteraction(d.localPosition),
      onTapDown: (d) => _handleInteraction(d.localPosition),
      child: CustomPaint(
        size: const Size(_outerRadius * 2, _outerRadius * 2),
        painter: _HueRingPainter(hue: hue),
      ),
    );
  }
}

class _HueRingPainter extends CustomPainter {
  final double hue;
  _HueRingPainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const outerR = _HueRing._outerRadius;
    const ringW = _HueRing._ringWidth;
    const innerR = outerR - ringW;

    // Draw hue ring with sweep gradient
    final gradientColors = List<Color>.generate(
      361,
      (i) => HSVColor.fromAHSV(1, i.toDouble(), 1, 1).toColor(),
    );
    final stops = List<double>.generate(361, (i) => i / 360);

    final paint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        stops: stops,
      ).createShader(Rect.fromCircle(center: center, radius: outerR))
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringW;

    canvas.drawCircle(center, innerR + ringW / 2, paint);

    // Thumb indicator
    final angle = hue * pi / 180;
    final thumbR = innerR + ringW / 2;
    final thumbCenter = Offset(
      center.dx + thumbR * cos(angle),
      center.dy + thumbR * sin(angle),
    );
    canvas.drawCircle(
      thumbCenter,
      ringW / 2 + 2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      thumbCenter,
      ringW / 2 - 1,
      Paint()..color = HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
    );
  }

  @override
  bool shouldRepaint(_HueRingPainter old) => old.hue != hue;
}

// ─────────────────────────────────────────────────────────────────────────────
// Saturation / Value Square
// ─────────────────────────────────────────────────────────────────────────────

class _SVSquare extends StatelessWidget {
  final double hue;
  final double saturation;
  final double value;
  final void Function(double s, double v) onChanged;

  const _SVSquare({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  // The square fits inside the hue ring
  static double get _side {
    const innerR = _HueRing._outerRadius - _HueRing._ringWidth;
    return innerR * sqrt2 * 0.7; // fit inside inner circle
  }

  void _handleInteraction(Offset localPosition) {
    final side = _side;
    final s = (localPosition.dx / side).clamp(0.0, 1.0);
    final v = 1.0 - (localPosition.dy / side).clamp(0.0, 1.0);
    onChanged(s, v);
  }

  @override
  Widget build(BuildContext context) {
    final side = _side;
    return GestureDetector(
      onPanStart: (d) => _handleInteraction(d.localPosition),
      onPanUpdate: (d) => _handleInteraction(d.localPosition),
      onTapDown: (d) => _handleInteraction(d.localPosition),
      child: SizedBox(
        width: side,
        height: side,
        child: CustomPaint(
          size: Size(side, side),
          painter: _SVSquarePainter(
            hue: hue,
            saturation: saturation,
            value: value,
          ),
        ),
      ),
    );
  }
}

class _SVSquarePainter extends CustomPainter {
  final double hue;
  final double saturation;
  final double value;

  _SVSquarePainter({
    required this.hue,
    required this.saturation,
    required this.value,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Horizontal gradient: white → hue colour (saturation)
    final hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hueColor],
        ).createShader(rect),
    );

    // Vertical gradient: transparent → black (value)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );

    // Thumb
    final dx = saturation * size.width;
    final dy = (1 - value) * size.height;
    final thumbColor = HSVColor.fromAHSV(1, hue, saturation, value).toColor();
    canvas.drawCircle(
      Offset(dx, dy),
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      Offset(dx, dy),
      6,
      Paint()..color = thumbColor,
    );
  }

  @override
  bool shouldRepaint(_SVSquarePainter old) =>
      old.hue != hue || old.saturation != saturation || old.value != value;
}
