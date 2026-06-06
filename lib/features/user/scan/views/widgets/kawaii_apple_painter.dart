import 'package:flutter/material.dart';

class KawaiiApplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw Apple Body (two overlapping circles for the classic apple shape)
    paint.color = const Color(0xFFEF5350); // beautiful apple red
    canvas.drawCircle(Offset(center.dx - 12, center.dy + 4), 28, paint);
    canvas.drawCircle(Offset(center.dx + 12, center.dy + 4), 28, paint);
    
    // Draw Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF795548)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final stemPath = Path()
      ..moveTo(center.dx, center.dy - 20)
      ..quadraticBezierTo(center.dx - 6, center.dy - 32, center.dx - 10, center.dy - 36);
    canvas.drawPath(stemPath, stemPaint);
    
    // Draw Leaf
    paint.color = const Color(0xFF81C784); // leaf green
    final leafPath = Path()
      ..moveTo(center.dx, center.dy - 24)
      ..quadraticBezierTo(center.dx + 12, center.dy - 34, center.dx + 16, center.dy - 24)
      ..quadraticBezierTo(center.dx + 6, center.dy - 20, center.dx, center.dy - 24)
      ..close();
    canvas.drawPath(leafPath, paint);
    
    // Eyes (Happy arcs)
    final eyePaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
      
    final leftEye = Path()
      ..moveTo(center.dx - 18, center.dy + 4)
      ..quadraticBezierTo(center.dx - 14, center.dy - 1, center.dx - 10, center.dy + 4);
    canvas.drawPath(leftEye, eyePaint);
    
    final rightEye = Path()
      ..moveTo(center.dx + 10, center.dy + 4)
      ..quadraticBezierTo(center.dx + 14, center.dy - 1, center.dx + 18, center.dy + 4);
    canvas.drawPath(rightEye, eyePaint);
    
    // Blush
    paint.color = const Color(0xFFFF8A80).withOpacity(0.8);
    canvas.drawCircle(Offset(center.dx - 22, center.dy + 9), 5, paint);
    canvas.drawCircle(Offset(center.dx + 22, center.dy + 9), 5, paint);
    
    // Smile
    final mouthPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final mouth = Path()
      ..moveTo(center.dx - 4, center.dy + 8)
      ..quadraticBezierTo(center.dx, center.dy + 12, center.dx + 4, center.dy + 8);
    canvas.drawPath(mouth, mouthPaint);

    // Scanning line (horizontal bright green scan line across the apple)
    final scanLinePaint = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - 40, center.dy - 4),
      Offset(center.dx + 40, center.dy - 4),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
