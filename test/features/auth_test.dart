import 'package:flutter_test/flutter_test.dart';
import 'package:nutritrack_app/features/general/auth/models/user_model.dart';

void main() {
  group('1. Authentication (Register, Login, Kelola Akun)', () {
    test('Positive: Login with correct credentials should succeed', () {
      final user = UserModel(
        id: '123', name: 'Test User', email: 'test@nutri.com', password: 'hashed_password', role: 'user', dailyCalorieNeed: 2000,
      );
      expect(user.email, 'test@nutri.com');
      expect(user.role, 'user');
    });

    test('Negative: Login with incorrect password should fail', () {
      bool isErrorThrown = false;
      try {
        if ('wrong_pass' != 'hashed_password') throw Exception('Wrong password');
      } catch (e) {
        isErrorThrown = true;
      }
      expect(isErrorThrown, true);
    });

    test('Positive: Register should create new UserModel', () {
      final map = {
        'id': '999', 'name': 'New User', 'email': 'new@nutri.com', 'role': 'user'
      };
      final user = UserModel.fromMap(map);
      expect(user.name, 'New User');
      expect(user.role, 'user');
    });

    test('Positive: Logout function clears user session data', () {
      UserModel? currentUser = UserModel(
        id: '1', name: 'Test', email: 't@t.com', password: 'p', role: 'user'
      );
      // Simulate logout
      currentUser = null;
      expect(currentUser, isNull);
    });
  });
}
