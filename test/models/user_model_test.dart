import 'package:flutter_test/flutter_test.dart';
import 'package:safechat/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    late UserModel userModel;

    setUp(() {
      userModel = UserModel();
    });

    test('should initialize with null username and not logged in', () {
      expect(userModel.username, isNull);
      expect(userModel.isLoggedIn, isFalse);
    });

    test('should update state when logging in', () {
      userModel.login('TestUser');

      expect(userModel.username, equals('TestUser'));
      expect(userModel.isLoggedIn, isTrue);
    });

    test('should update state when logging out', () {
      // First login
      userModel.login('TestUser');
      expect(userModel.isLoggedIn, isTrue);

      // Then logout
      userModel.logout();
      expect(userModel.username, isNull);
      expect(userModel.isLoggedIn, isFalse);
    });

    test('should notify listeners when logging in', () {
      var notificationCount = 0;
      userModel.addListener(() => notificationCount++);

      userModel.login('TestUser');
      expect(notificationCount, equals(1));
    });

    test('should notify listeners when logging out', () {
      var notificationCount = 0;
      userModel.addListener(() => notificationCount++);

      userModel.login('TestUser');
      userModel.logout();
      expect(notificationCount, equals(2));
    });
  });
}
