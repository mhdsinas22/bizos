import 'package:flutter/material.dart';

/// A custom painter that draws a subtle, organic gradient wave at the bottom
/// of financial cards, closely matching the reference SaaS design.
class CardWavePainter extends CustomPainter {
  final Color color;

  const CardWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // Filled wave area
    final fillPath = Path();
    fillPath.moveTo(0, h * 0.72);
    fillPath.cubicTo(
      w * 0.28, h * 0.90,
      w * 0.48, h * 0.68,
      w * 0.74, h * 0.52,
    );
    fillPath.quadraticBezierTo(
      w * 0.88, h * 0.44,
      w, h * 0.50,
    );
    fillPath.lineTo(w, h);
    fillPath.lineTo(0, h);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          color.withValues(alpha: 0.22),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.4, w, h * 0.6))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Subtle stroke along the crest of the wave
    final crestPath = Path();
    crestPath.moveTo(0, h * 0.72);
    crestPath.cubicTo(
      w * 0.28, h * 0.90,
      w * 0.48, h * 0.68,
      w * 0.74, h * 0.52,
    );
    crestPath.quadraticBezierTo(
      w * 0.88, h * 0.44,
      w, h * 0.50,
    );

    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.38)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(crestPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CardWavePainter oldDelegate) =>
      oldDelegate.color != color;
}
