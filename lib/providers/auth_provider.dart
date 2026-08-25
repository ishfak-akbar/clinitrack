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
  static const String _keyQualifications = 'user_qualifications';
  static const String _keyExperienceYears = 'user_experience_years';
  static const String _keyClinicAddress = 'user_clinic_address';
  static const String _keyBio = 'user_bio';
  static const String _keyMemberSince = 'user_member_since';

  bool _isLoggedIn = false;
  String _email = '';
  String _role = 'Doctor';
  bool _isLoading = true;

  String _name = 'Dr. Ishfak Akbar';
  String _specialty = 'General Physician';
  String _licenseNumber = 'MBBS-214578';
  String _phone = '01912345678';
  String _qualifications = 'MBBS, FCPS (Medicine)';
  String _experienceYears = '5';
  String _clinicAddress = 'Zindabazar, Sylhet';
  String _bio = '';
  String _memberSince = '';

  bool get isLoggedIn => _isLoggedIn;
  String get email => _email;
  String get role => _role;
  bool get isLoading => _isLoading;

  String get name => _name;
  String get specialty => _specialty;
  String get licenseNumber => _licenseNumber;
  String get phone => _phone;
  String get qualifications => _qualifications;
  String get experienceYears => _experienceYears;
  String get clinicAddress => _clinicAddress;
  String get bio => _bio;
  String get memberSince => _memberSince;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    _email = prefs.getString(_keyEmail) ?? '';
    _role = prefs.getString(_keyRole) ?? 'Doctor';
    _name = prefs.getString(_keyName) ?? _name;
    _specialty = prefs.getString(_keySpecialty) ?? _specialty;
    _licenseNumber = prefs.getString(_keyLicenseNumber) ?? _licenseNumber;
    _phone = prefs.getString(_keyPhone) ?? _phone;
    _qualifications = prefs.getString(_keyQualifications) ?? _qualifications;
    _experienceYears = prefs.getString(_keyExperienceYears) ?? _experienceYears;
    _clinicAddress = prefs.getString(_keyClinicAddress) ?? _clinicAddress;
    _bio = prefs.getString(_keyBio) ?? _bio;

    // Set member-since once, the first time a session is ever loaded.
    _memberSince = prefs.getString(_keyMemberSince) ?? '';
    if (_memberSince.isEmpty) {
      _memberSince = _formatDate(DateTime.now());
      await prefs.setString(_keyMemberSince, _memberSince);
    }

    _isLoading = false;
    notifyListeners();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
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
    required String qualifications,
    required String experienceYears,
    required String clinicAddress,
    required String bio,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keySpecialty, specialty);
    await prefs.setString(_keyLicenseNumber, licenseNumber);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyQualifications, qualifications);
    await prefs.setString(_keyExperienceYears, experienceYears);
    await prefs.setString(_keyClinicAddress, clinicAddress);
    await prefs.setString(_keyBio, bio);

    _name = name;
    _specialty = specialty;
    _licenseNumber = licenseNumber;
    _email = email;
    _phone = phone;
    _qualifications = qualifications;
    _experienceYears = experienceYears;
    _clinicAddress = clinicAddress;
    _bio = bio;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);

    _isLoggedIn = false;
    notifyListeners();
  }
}