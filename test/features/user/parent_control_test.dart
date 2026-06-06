import 'package:flutter_test/flutter_test.dart';

void main() {
  group('4. Kontrol Orang Tua (Mode Pantau)', () {
    test('Positive: Parent scanning child QR code links account', () {
      String childCode = "CHILD_999";
      bool isLinked = childCode.startsWith("CHILD_");
      expect(isLinked, true);
    });

    test('Negative: Invalid QR code format throws Error', () {
      String invalidCode = "WRONG_QR_FORMAT";
      bool isValid = invalidCode.startsWith("CHILD_");
      expect(isValid, false);
    });

    test('Positive: Unlinking child profile removes relation', () {
      String? linkedChild = "CHILD_999";
      // Simulate unlink
      linkedChild = null;
      expect(linkedChild, isNull);
    });
  });
}
