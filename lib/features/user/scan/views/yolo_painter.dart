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

class YoloCoverPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final int origWidth;
  final int origHeight;
  final double screenWidth;
  final double screenHeight;

  YoloCoverPainter({
    required this.detections,
    required this.origWidth,
    required this.origHeight,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (origWidth == 0 || origHeight == 0) return;

    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 1. Math for preprocessed 640x640 to original image mapping
    const targetSize = 640.0;
    final double ratio = targetSize / (origWidth > origHeight ? origWidth : origHeight);
    final double newWidth = origWidth * ratio;
    final double newHeight = origHeight * ratio;
    final double dstX = (targetSize - newWidth) / 2;
    final double dstY = (targetSize - newHeight) / 2;

    // 2. Math for original image to BoxFit.cover screen mapping
    final double scale = (screenWidth / origWidth) > (screenHeight / origHeight)
        ? (screenWidth / origWidth)
        : (screenHeight / origHeight);
    final double dx = (screenWidth - origWidth * scale) / 2;
    final double dy = (screenHeight - origHeight * scale) / 2;

    for (var detection in detections) {
      final box = detection['box2d']; // [x1, y1, x2, y2]
      if (box == null) continue;

      // Map from 640x640 preprocessed coordinate space to original image space
      final double x1Orig = (box[0] - dstX) / ratio;
      final double y1Orig = (box[1] - dstY) / ratio;
      final double x2Orig = (box[2] - dstX) / ratio;
      final double y2Orig = (box[3] - dstY) / ratio;

      // Map from original image space to BoxFit.cover screen space
      final double x1Screen = x1Orig * scale + dx;
      final double y1Screen = y1Orig * scale + dy;
      final double x2Screen = x2Orig * scale + dx;
      final double y2Screen = y2Orig * scale + dy;

      final rect = Rect.fromLTRB(x1Screen, y1Screen, x2Screen, y2Screen);
      canvas.drawRect(rect, paint);

      final label = "${detection['tag']} ${(detection['box'][4] * 100).toStringAsFixed(0)}%";
      
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          backgroundColor: Color(0xFF4CAF50),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x1Screen, (y1Screen - 14).clamp(0.0, screenHeight)));
    }
  }

  @override
  bool shouldRepaint(covariant YoloCoverPainter oldDelegate) => true;
}
