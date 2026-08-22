import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyEmail = 'user_email';
  static const String _keyRole = 'user_role';

  bool _isLoggedIn = false;
  String _email = '';
  String _role = 'Doctor';
  bool _isLoading = true;

  bool get isLoggedIn => _isLoggedIn;
  String get email => _email;
  String get role => _role;
  bool get isLoading => _isLoading;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    _email = prefs.getString(_keyEmail) ?? '';
    _role = prefs.getString(_keyRole) ?? 'Doctor';
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login({required String email, required String role}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyRole, role);

    _isLoggedIn = true;
    _email = email;
    _role = role;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);

    _isLoggedIn = false;
    notifyListeners();
  }
}