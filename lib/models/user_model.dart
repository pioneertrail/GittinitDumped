import 'package:flutter/foundation.dart';

class UserModel extends ChangeNotifier {
  String? _username;
  bool _isLoggedIn = false;

  String? get username => _username;
  bool get isLoggedIn => _isLoggedIn;

  void login(String username) {
    print('DEBUG: UserModel - Logging in user: $username');
    _username = username;
    _isLoggedIn = true;
    notifyListeners();
    print('DEBUG: UserModel - Login complete, notified listeners');
  }

  void logout() {
    print('DEBUG: UserModel - Logging out user: $_username');
    _username = null;
    _isLoggedIn = false;
    notifyListeners();
    print('DEBUG: UserModel - Logout complete, notified listeners');
  }
}
