import 'package:flutter/material.dart';

class YoloPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final int imageHeight;
  final int imageWidth;

  YoloPainter({
    required this.detections,
    required this.imageHeight,
    required this.imageWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var detection in detections) {
      final box = detection['box2d']; // [x1, y1, x2, y2]
      if (box == null) continue;

      final double x1 = box[0] * size.width / imageWidth;
      final double y1 = box[1] * size.height / imageHeight;
      final double x2 = box[2] * size.width / imageWidth;
      final double y2 = box[3] * size.height / imageHeight;

      final rect = Rect.fromLTRB(x1, y1, x2, y2);
      canvas.drawRect(rect, paint);

      final label = "${detection['tag']} ${(detection['box'][4] * 100).toStringAsFixed(0)}%";
      
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          backgroundColor: Color(0xFF4CAF50),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x1, y1 - 12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
