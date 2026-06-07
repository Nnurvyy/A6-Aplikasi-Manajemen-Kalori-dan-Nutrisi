import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nutritrack_app/helpers/pcd_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PCD Image Preprocessing (PCDHelper)', () {
    test('Positive: processForYolo resizes and letterboxes image to 640x640', () async {
      // 1. Create a simple 100x200 image in memory
      final image = img.Image(width: 100, height: 200);
      // Fill with red
      img.fill(image, color: img.ColorRgb8(255, 0, 0));
      
      final originalBytes = Uint8List.fromList(img.encodeJpg(image));

      // 2. Process via PCDHelper
      final processedBytes = await PCDHelper.processForYolo(originalBytes);
      
      expect(processedBytes, isNotNull);
      
      // 3. Decode output and verify it is letterboxed to 640x640
      final processedImage = img.decodeImage(processedBytes!);
      expect(processedImage, isNotNull);
      expect(processedImage!.width, 640);
      expect(processedImage.height, 640);
    });

    test('Negative: processForYolo returns null for invalid image bytes', () async {
      final invalidBytes = Uint8List.fromList([0, 1, 2, 3, 4, 5]);
      final processedBytes = await PCDHelper.processForYolo(invalidBytes);
      expect(processedBytes, isNull);
    });
  });
}
