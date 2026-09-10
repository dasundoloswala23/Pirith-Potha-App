import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The app's "dhamma wheel" mark — a ring with a filled center dot and 8
/// short inner spokes — used as the splash/app-bar logo and as the default
/// artwork placeholder before a Pirith has real cover art. Matches the
/// `Icon.dhamma` SVG in the approved UI reference
/// (`Buddhist Audio App UI Design/src/App.tsx`): a 24x24 viewBox circle of
/// r=10 with spokes running from r=3.5 to r=7.5.
class PirithMark extends StatelessWidget {
  const PirithMark({
    required this.size,
    this.color,
    this.strokeWidth = 2,
    super.key,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final markColor = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PirithMarkPainter(color: markColor, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _PirithMarkPainter extends CustomPainter {
  _PirithMarkPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  static const _spokeCount = 8;
  // Fractions of the canvas half-size (R), matching the 24x24 reference
  // viewBox where the canvas half is 12: ring r=10/12, dot r=3/12, spokes
  // from r=3.5/12 to r=7.5/12.
  static const _ringFraction = 10 / 12;
  static const _dotFraction = 3 / 12;
  static const _spokeInnerFraction = 3.5 / 12;
  static const _spokeOuterFraction = 7.5 / 12;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, r * _ringFraction, strokePaint);
    canvas.drawCircle(center, r * _dotFraction, fillPaint);

    for (var i = 0; i < _spokeCount; i++) {
      final angle = (2 * math.pi / _spokeCount) * i;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (r * _spokeInnerFraction),
        center + direction * (r * _spokeOuterFraction),
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PirithMarkPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
