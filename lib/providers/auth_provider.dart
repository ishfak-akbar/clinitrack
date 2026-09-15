import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

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
  String _errorMessage = '';

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
  String get errorMessage => _errorMessage;

  String get name => _name;
  String get specialty => _specialty;
  String get licenseNumber => _licenseNumber;
  String get phone => _phone;
  String get qualifications => _qualifications;
  String get experienceYears => _experienceYears;
  String get clinicAddress => _clinicAddress;
  String get bio => _bio;
  String get memberSince => _memberSince;

  bool get useBackend => SupabaseConfig.isConfigured;
  String? get userId => useBackend
      ? SupabaseConfig.client.auth.currentUser?.id
      : null;

  Future<void> loadSession() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    if (useBackend) {
      await _loadSupabaseSession();
    } else {
      await _loadLocalSession();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSupabaseSession() async {
    try {
      final session = SupabaseConfig.client.auth.currentSession;
      if (session?.user == null) {
        _isLoggedIn = false;
        return;
      }
      _isLoggedIn = true;
      _email = session!.user.email ?? '';
      await _loadProfile();
    } catch (_) {
      _isLoggedIn = false;
    }
  }

  Future<void> _loadProfile() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    try {
      final row = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (row != null) {
        _name = (row['full_name'] as String?) ?? _name;
        _role = (row['role'] as String?) ?? _role;
        _specialty = (row['specialty'] as String?) ?? _specialty;
        _licenseNumber = (row['license_number'] as String?) ?? _licenseNumber;
        _phone = (row['phone'] as String?) ?? _phone;
        _qualifications = (row['qualifications'] as String?) ?? _qualifications;
        _experienceYears = (row['experience_years'] as String?) ?? _experienceYears;
        _clinicAddress = (row['clinic_address'] as String?) ?? _clinicAddress;
        _bio = (row['bio'] as String?) ?? _bio;
        if (_email.isEmpty) _email = (row['email'] as String?) ?? '';
      }
      await _cacheToPrefs();
    } catch (_) {
      // Table/RLS not ready yet — stay logged in with auth email only.
      await _cacheToPrefs();
    }
  }

  Future<void> _loadLocalSession() async {
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

    _memberSince = prefs.getString(_keyMemberSince) ?? '';
    if (_memberSince.isEmpty) {
      _memberSince = _formatDate(DateTime.now());
      await prefs.setString(_keyMemberSince, _memberSince);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  /// Returns true on success, false on failure (see [errorMessage]).
  Future<bool> login({required String email, required String password, String role = 'Doctor'}) async {
    _errorMessage = '';
    notifyListeners();

    if (!useBackend) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyEmail, email);
      await prefs.setString(_keyRole, role);
      _isLoggedIn = true;
      _email = email;
      _role = role;
      notifyListeners();
      return true;
    }

    try {
      final res = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.session == null) {
        _errorMessage = 'Sign in failed. Please try again.';
        notifyListeners();
        return false;
      }
      _isLoggedIn = true;
      _email = res.user?.email ?? email;
      _role = role;
      await _loadProfile();
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Sign in failed. Check connection and try again.';
      notifyListeners();
      return false;
    }
  }

  /// Returns true on success, false on failure (see [errorMessage]).
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _errorMessage = '';
    notifyListeners();

    if (!useBackend) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyEmail, email);
      await prefs.setString(_keyName, fullName);
      _isLoggedIn = true;
      _email = email;
      _name = fullName;
      notifyListeners();
      return true;
    }

    try {
      final res = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      final user = res.user;
      if (user == null) {
        _errorMessage = 'Sign up failed. Please try again.';
        notifyListeners();
        return false;
      }
      // With email confirmation OFF, session exists immediately.
      _isLoggedIn = res.session != null;
      _email = user.email ?? email;
      _name = fullName;
      if (_isLoggedIn) {
        await _loadProfile();
        // Ensure display name persisted even if trigger ran first.
        await _persistProfileName(fullName);
      } else {
        _errorMessage = 'Account created. Check your email to confirm, then sign in.';
      }
      notifyListeners();
      return res.session != null;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Sign up failed. Check connection and try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> _persistProfileName(String fullName) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    try {
      await SupabaseConfig.client.from('profiles').upsert({
        'id': user.id,
        'email': _email,
        'full_name': fullName,
      });
    } catch (_) {
      // Non-fatal — trigger already created the row.
    }
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

    await _cacheToPrefs();

    if (!useBackend) return;
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    try {
      await SupabaseConfig.client.from('profiles').update({
        'full_name': name,
        'specialty': specialty,
        'license_number': licenseNumber,
        'email': email,
        'phone': phone,
        'qualifications': qualifications,
        'experience_years': experienceYears,
        'clinic_address': clinicAddress,
        'bio': bio,
      }).eq('id', user.id);
    } catch (e) {
      _errorMessage = 'Profile saved locally, cloud sync failed.';
      notifyListeners();
    }
  }

  Future<void> _cacheToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, _isLoggedIn);
    await prefs.setString(_keyEmail, _email);
    await prefs.setString(_keyRole, _role);
    await prefs.setString(_keyName, _name);
    await prefs.setString(_keySpecialty, _specialty);
    await prefs.setString(_keyLicenseNumber, _licenseNumber);
    await prefs.setString(_keyPhone, _phone);
    await prefs.setString(_keyQualifications, _qualifications);
    await prefs.setString(_keyExperienceYears, _experienceYears);
    await prefs.setString(_keyClinicAddress, _clinicAddress);
    await prefs.setString(_keyBio, _bio);
    if (_memberSince.isEmpty) {
      _memberSince = _formatDate(DateTime.now());
    }
    await prefs.setString(_keyMemberSince, _memberSince);
  }

  Future<void> logout() async {
    if (useBackend) {
      try {
        await SupabaseConfig.client.auth.signOut();
      } catch (_) {
        // Still log out locally.
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);

    _isLoggedIn = false;
    _errorMessage = '';
    notifyListeners();
  }
}
