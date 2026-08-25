import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyAppointmentReminder = 'appointment_reminder';
  static const String _keyLanguage = 'language';

  bool _darkMode = false;
  bool _appointmentReminder = true;
  String _language = 'English';

  bool get darkMode => _darkMode;
  bool get appointmentReminder => _appointmentReminder;
  String get language => _language;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool(_keyDarkMode) ?? false;
    _appointmentReminder = prefs.getBool(_keyAppointmentReminder) ?? true;
    _language = prefs.getString(_keyLanguage) ?? 'English';
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
    _darkMode = value;
    notifyListeners();
  }

  Future<void> setAppointmentReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAppointmentReminder, value);
    _appointmentReminder = value;
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, value);
    _language = value;
    notifyListeners();
  }
}