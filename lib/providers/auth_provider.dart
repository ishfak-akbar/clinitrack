import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyEmail = 'user_email';
  static const String _keyRole = 'user_role';
  static const String _keyName = 'user_name';
  static const String _keySpecialty = 'user_specialty';
  static const String _keyLicenseNumber = 'user_license_number';
  static const String _keyPhone = 'user_phone';

  bool _isLoggedIn = false;
  String _email = '';
  String _role = 'Doctor';
  bool _isLoading = true;

  String _name = 'Dr. Ishfak Akbar';
  String _specialty = 'General Physician';
  String _licenseNumber = 'MBBS-214578';
  String _phone = '01912345678';

  bool get isLoggedIn => _isLoggedIn;
  String get email => _email;
  String get role => _role;
  bool get isLoading => _isLoading;

  String get name => _name;
  String get specialty => _specialty;
  String get licenseNumber => _licenseNumber;
  String get phone => _phone;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    _email = prefs.getString(_keyEmail) ?? '';
    _role = prefs.getString(_keyRole) ?? 'Doctor';
    _name = prefs.getString(_keyName) ?? _name;
    _specialty = prefs.getString(_keySpecialty) ?? _specialty;
    _licenseNumber = prefs.getString(_keyLicenseNumber) ?? _licenseNumber;
    _phone = prefs.getString(_keyPhone) ?? _phone;
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

  Future<void> updateProfile({
    required String name,
    required String specialty,
    required String licenseNumber,
    required String email,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keySpecialty, specialty);
    await prefs.setString(_keyLicenseNumber, licenseNumber);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPhone, phone);

    _name = name;
    _specialty = specialty;
    _licenseNumber = licenseNumber;
    _email = email;
    _phone = phone;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);

    _isLoggedIn = false;
    notifyListeners();
  }
}