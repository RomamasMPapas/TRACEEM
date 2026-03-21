import 'package:flutter/material.dart';

/// Custom painter that draws a decorative wavy curve line used as a background
/// element on the [LoginScreen] landing view.
class CurvePainter extends CustomPainter {
  /// Draws the bezier curve path onto the canvas.
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.black.withValues(alpha: 0.8);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.0;

    var path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.7,
      size.width * 0.5,
      size.height * 0.85,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 1,
      size.width,
      size.height * 0.9,
    );

    canvas.drawPath(path, paint);
  }

  /// Returns false because the curve is static and never needs to be repainted.
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
