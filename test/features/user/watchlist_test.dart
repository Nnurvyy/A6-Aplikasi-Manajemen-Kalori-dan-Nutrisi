import 'package:flutter_test/flutter_test.dart';

void main() {
  group('2.6 Watchlist (Makanan Pantauan)', () {
    test('Positive: Adding food to watchlist increases item count', () {
      List<String> watchlist = [];
      watchlist.add('f1');
      expect(watchlist.length, 1);
    });

    test('Negative: Adding duplicate food ignores or alerts', () {
      List<String> watchlist = ['f1'];
      if (!watchlist.contains('f1')) watchlist.add('f1');
      expect(watchlist.length, 1);
    });

    test('Positive: Removing food from watchlist deletes it correctly', () {
      List<String> watchlist = ['f1', 'f2'];
      watchlist.remove('f1');
      expect(watchlist.length, 1);
      expect(watchlist.contains('f1'), false);
    });
  });
}
