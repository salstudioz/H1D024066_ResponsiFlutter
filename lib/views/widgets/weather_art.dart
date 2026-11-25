import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ilustrasi cuaca berlapis (paper-cut / 3D aesthetic)
/// Mengikuti gaya visual modern seperti pada referensi desain.
class WeatherArtWidget extends StatelessWidget {
  const WeatherArtWidget({
    super.key,
    required this.weatherCode,
    this.size = 130,
    this.isNight = false,
  });

  final int weatherCode;
  final double size;
  final bool isNight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WeatherArtPainter(
          weatherCode: weatherCode,
          isNight: isNight,
        ),
      ),
    );
  }
}

class _WeatherArtPainter extends CustomPainter {
  _WeatherArtPainter({required this.weatherCode, required this.isNight});

  final int weatherCode;
  final bool isNight;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 0, 1: Cerah
    // 2, 3: Berawan
    // 45, 48: Kabut
    // 51..67: Hujan / Gerimis
    // 71..86: Salju
    // 95..99: Badai petir
    if (weatherCode == 0 || weatherCode == 1) {
      if (isNight) {
        _drawMoon(canvas, w, h);
      } else {
        _drawSun(canvas, w, h);
      }
    } else if (weatherCode == 2 || weatherCode == 3) {
      if (weatherCode == 2 && !isNight) {
        _drawSunBehindCloud(canvas, w, h);
      } else {
        _drawCloud(canvas, w, h, isOvercast: weatherCode == 3);
      }
    } else if (weatherCode == 45 || weatherCode == 48) {
      _drawFog(canvas, w, h);
    } else if (weatherCode >= 95 && weatherCode <= 99) {
      _drawThunderstorm(canvas, w, h);
    } else if (weatherCode >= 71 && weatherCode <= 86) {
      _drawSnow(canvas, w, h);
    } else {
      // Hujan (default rain)
      _drawRain(canvas, w, h);
    }
  }

  /// Matahari bersinar berlapis dengan soft outer glow
  void _drawSun(Canvas canvas, double w, double h) {
    final center = Offset(w * 0.5, h * 0.5);
    final radius = w * 0.32;

    // Outer glow ring
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFE082).withValues(alpha: 0.5),
          const Color(0xFFFFB300).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.55));
    canvas.drawCircle(center, radius * 1.55, glowPaint);

    // Second soft halo
    final haloPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.4);
    canvas.drawCircle(center, radius * 1.25, haloPaint);

    // Core bright sun
    final corePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF176), Color(0xFFFF8F00)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, corePaint);

    // Highlight reflection
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.28, center.dy - radius * 0.28),
      radius * 0.35,
      highlightPaint,
    );
  }

  /// Bulan sabit bercahaya dengan bintang
  void _drawMoon(Canvas canvas, double w, double h) {
    final center = Offset(w * 0.5, h * 0.5);
    final radius = w * 0.32;

    // Moon halo
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF81D4FA).withValues(alpha: 0.4),
          const Color(0xFF0288D1).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.6));
    canvas.drawCircle(center, radius * 1.6, glow);

    // Crescent Moon path
    final moonPath = Path()
      ..addArc(Rect.fromCircle(center: center, radius: radius), -1.1, 4.3)
      ..arcToPoint(
        Offset(center.dx + radius * math.cos(-1.1),
            center.dy + radius * math.sin(-1.1)),
        radius: Radius.circular(radius * 1.05),
        clockwise: false,
      );

    final moonPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFCFD8DC), Color(0xFF90A4AE)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(moonPath, moonPaint);

    // Stars
    _drawStar(canvas, Offset(w * 0.22, h * 0.28), 3.5, Colors.white);
    _drawStar(canvas, Offset(w * 0.78, h * 0.25), 4.0, const Color(0xFFFFF9C4));
    _drawStar(canvas, Offset(w * 0.72, h * 0.75), 2.5, Colors.white);
  }

  void _drawStar(Canvas canvas, Offset p, double r, Color color) {
    final paint = Paint()..color = color;
    canvas.drawCircle(p, r, paint);
    final glow = Paint()..color = color.withValues(alpha: 0.3);
    canvas.drawCircle(p, r * 2.2, glow);
  }

  /// Matahari di balik awan
  void _drawSunBehindCloud(Canvas canvas, double w, double h) {
    // Draw sun on top-right
    final sunCenter = Offset(w * 0.68, h * 0.36);
    final sunRadius = w * 0.22;

    final sunHalo = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.45);
    canvas.drawCircle(sunCenter, sunRadius * 1.35, sunHalo);

    final sunPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF59D), Color(0xFFFF9800)],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));
    canvas.drawCircle(sunCenter, sunRadius, sunPaint);

    // Draw Cloud in front
    _drawCloudShape(
      canvas,
      Offset(w * 0.44, h * 0.58),
      w * 0.75,
      h * 0.46,
      baseColor: const Color(0xFFFFFFFF),
      shadowColor: const Color(0xFFB0BEC5),
    );
  }

  /// Awan lembut 3D berlapis
  void _drawCloud(Canvas canvas, double w, double h, {bool isOvercast = false}) {
    // Back shadow cloud
    _drawCloudShape(
      canvas,
      Offset(w * 0.52, h * 0.54),
      w * 0.78,
      h * 0.48,
      baseColor: isOvercast ? const Color(0xFF78909C) : const Color(0xFFCFD8DC),
      shadowColor:
          isOvercast ? const Color(0xFF455A64) : const Color(0xFF90A4AE),
    );

    // Main front cloud
    _drawCloudShape(
      canvas,
      Offset(w * 0.48, h * 0.48),
      w * 0.78,
      h * 0.48,
      baseColor: isOvercast ? const Color(0xFFB0BEC5) : const Color(0xFFFFFFFF),
      shadowColor:
          isOvercast ? const Color(0xFF78909C) : const Color(0xFFB0BEC5),
    );
  }

  void _drawCloudShape(
    Canvas canvas,
    Offset center,
    double cw,
    double ch, {
    required Color baseColor,
    required Color shadowColor,
  }) {
    final left = center.dx - cw / 2;
    final top = center.dy - ch / 2;

    final path = Path();
    // Rounded base pill
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top + ch * 0.35, cw, ch * 0.6),
      Radius.circular(ch * 0.3),
    );
    path.addRRect(baseRect);

    // Puffs
    path.addOval(Rect.fromCircle(
      center: Offset(left + cw * 0.3, top + ch * 0.42),
      radius: ch * 0.36,
    ));
    path.addOval(Rect.fromCircle(
      center: Offset(left + cw * 0.55, top + ch * 0.32),
      radius: ch * 0.42,
    ));
    path.addOval(Rect.fromCircle(
      center: Offset(left + cw * 0.76, top + ch * 0.46),
      radius: ch * 0.30,
    ));

    // Shadow / depth
    final shadowPaint = Paint()
      ..color = shadowColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, shadowPaint);

    // Fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [baseColor, shadowColor],
      ).createShader(Rect.fromLTWH(left, top, cw, ch));
    canvas.drawPath(path, fillPaint);
  }

  /// Awan hujan dengan tetesan air
  void _drawRain(Canvas canvas, double w, double h) {
    _drawCloud(canvas, w, h * 0.9);

    final dropPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF64B5F6), Color(0xFF1E88E5)],
      ).createShader(Rect.fromLTWH(0, h * 0.65, w, h * 0.35))
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    final drops = [
      Offset(w * 0.32, h * 0.72),
      Offset(w * 0.46, h * 0.76),
      Offset(w * 0.60, h * 0.70),
      Offset(w * 0.72, h * 0.75),
    ];

    for (final drop in drops) {
      canvas.drawLine(
        drop,
        Offset(drop.dx - 2.5, drop.dy + 14),
        dropPaint,
      );
    }
  }

  /// Badai petir dengan kilat neon
  void _drawThunderstorm(Canvas canvas, double w, double h) {
    _drawCloud(canvas, w, h * 0.88, isOvercast: true);

    // Lightning bolt
    final bolt = Path()
      ..moveTo(w * 0.52, h * 0.62)
      ..lineTo(w * 0.44, h * 0.78)
      ..lineTo(w * 0.50, h * 0.78)
      ..lineTo(w * 0.42, h * 0.96)
      ..lineTo(w * 0.58, h * 0.74)
      ..lineTo(w * 0.51, h * 0.74)
      ..close();

    final glow = Paint()
      ..color = const Color(0xFFFFEB3B).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(bolt, glow);

    final boltPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFFFD600)],
      ).createShader(Rect.fromLTWH(w * 0.4, h * 0.6, w * 0.2, h * 0.4));
    canvas.drawPath(bolt, boltPaint);
  }

  /// Kabut berlapis garis horizontal halus
  void _drawFog(Canvas canvas, double w, double h) {
    final barPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.0;

    final lines = [
      (Offset(w * 0.20, h * 0.35), Offset(w * 0.80, h * 0.35), 0.6),
      (Offset(w * 0.15, h * 0.48), Offset(w * 0.85, h * 0.48), 0.8),
      (Offset(w * 0.25, h * 0.61), Offset(w * 0.75, h * 0.61), 0.5),
      (Offset(w * 0.18, h * 0.74), Offset(w * 0.82, h * 0.74), 0.7),
    ];

    for (final line in lines) {
      barPaint.color = Colors.white.withValues(alpha: line.$3);
      canvas.drawLine(line.$1, line.$2, barPaint);
    }
  }

  /// Salju
  void _drawSnow(Canvas canvas, double w, double h) {
    _drawCloud(canvas, w, h * 0.9);

    final flakePaint = Paint()..color = Colors.white;
    final flakes = [
      Offset(w * 0.30, h * 0.74),
      Offset(w * 0.45, h * 0.80),
      Offset(w * 0.60, h * 0.72),
      Offset(w * 0.72, h * 0.78),
    ];

    for (final f in flakes) {
      canvas.drawCircle(f, 3.5, flakePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherArtPainter oldDelegate) =>
      oldDelegate.weatherCode != weatherCode ||
      oldDelegate.isNight != isNight;
}

