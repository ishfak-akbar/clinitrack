import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/auth_repository.dart';

/// Step 14: UI/session state only — all Supabase auth + `profiles`
/// access goes through [AuthRepository].
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

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
  static const String _keyAvatarUrl = 'user_avatar_url';
  static const String _keyMemberSince = 'user_member_since';
  static const String _keyChamberName = 'user_chamber_name';
  static const String _keyTitle = 'user_title';
  static const String _keyDegree = 'user_degree';
  static const String _keyGraduatingInstitution = 'user_graduating_institution';
  static const String _keyGraduationYear = 'user_graduation_year';
  static const String _keySpecialties = 'user_specialties';
  static const String _keyVerificationStatus = 'user_verification_status';
  static const String _keyRejectionReason = 'user_rejection_reason';

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
  String _avatarUrl = '';
  String _memberSince = '';

  // Step 2 (doctor verification): credential + application state.
  // Mirrors supabase/doctor_verification.sql; cached for offline use.
  String _chamberName = '';
  String _title = '';
  String _degree = '';
  String _graduatingInstitution = '';
  String _graduationYear = '';
  List<String> _specialties = [];
  String _verificationStatus = 'approved';
  String _rejectionReason = '';

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
  String get avatarUrl => _avatarUrl;
  String get memberSince => _memberSince;

  String get chamberName => _chamberName;
  String get title => _title;
  String get degree => _degree;
  String get graduatingInstitution => _graduatingInstitution;
  String get graduationYear => _graduationYear;
  List<String> get specialties => List.unmodifiable(_specialties);
  String get verificationStatus => _verificationStatus;
  String get rejectionReason => _rejectionReason;

  bool get isAdmin => _role == 'Admin';

  bool get useBackend => _repo.useBackend;
  String? get userId => _repo.userId;

  /// Home route for the signed-in role (Part 5: patient portal).
  bool get isPatient => _role == 'Patient';
  String get homeRoute => isPatient ? '/patient-home' : '/dashboard';

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
      if (!_repo.hasSession) {
        _isLoggedIn = false;
        return;
      }
      _isLoggedIn = true;
      _email = _repo.currentEmail;
      await _loadProfile();
    } catch (_) {
      _isLoggedIn = false;
    }
  }

  Future<void> _loadProfile() async {
    final row = await _repo.fetchProfile();
    if (row != null) {
      _name = (row['full_name'] as String?) ?? _name;
      _role = (row['role'] as String?) ?? _role;
      _specialty = (row['specialty'] as String?) ?? _specialty;
      _licenseNumber = (row['license_number'] as String?) ?? _licenseNumber;
      _phone = (row['phone'] as String?) ?? _phone;
      _qualifications = (row['qualifications'] as String?) ?? _qualifications;
      _experienceYears =
          (row['experience_years'] as String?) ?? _experienceYears;
      _clinicAddress = (row['clinic_address'] as String?) ?? _clinicAddress;
      _bio = (row['bio'] as String?) ?? _bio;
      _avatarUrl = (row['avatar_url'] as String?) ?? _avatarUrl;
      if (_email.isEmpty) _email = (row['email'] as String?) ?? '';
      _chamberName = (row['chamber_name'] as String?) ?? '';
      _title = (row['title'] as String?) ?? '';
      _degree = (row['degree'] as String?) ?? '';
      _graduatingInstitution =
          (row['graduating_institution'] as String?) ?? '';
      final gradYear = row['graduation_year'];
      _graduationYear = gradYear == null ? '' : gradYear.toString();
      _specialties = (row['specialties'] as List?)
              ?.map((e) => e.toString())
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          [];
      // Unknown (pre-migration DB) means approved — preserves old behavior.
      _verificationStatus =
          (row['verification_status'] as String?) ?? 'approved';
      _rejectionReason = (row['rejection_reason'] as String?) ?? '';
    }
    await _cacheToPrefs();
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
    _avatarUrl = prefs.getString(_keyAvatarUrl) ?? _avatarUrl;

    _chamberName = prefs.getString(_keyChamberName) ?? '';
    _title = prefs.getString(_keyTitle) ?? '';
    _degree = prefs.getString(_keyDegree) ?? '';
    _graduatingInstitution =
        prefs.getString(_keyGraduatingInstitution) ?? '';
    _graduationYear = prefs.getString(_keyGraduationYear) ?? '';
    _specialties = prefs.getStringList(_keySpecialties) ?? [];
    _verificationStatus =
        prefs.getString(_keyVerificationStatus) ?? 'approved';
    _rejectionReason = prefs.getString(_keyRejectionReason) ?? '';

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
      final result = await _repo.signIn(email: email, password: password);
      _isLoggedIn = true;
      _email = result.email;
      _role = role;
      await _loadProfile();
      notifyListeners();
      return true;
    } on AuthFailure catch (e) {
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
    String role = 'Doctor',
  }) async {
    _errorMessage = '';
    notifyListeners();

    if (!useBackend) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyEmail, email);
      await prefs.setString(_keyName, fullName);
      await prefs.setString(_keyRole, role);
      _isLoggedIn = true;
      _email = email;
      _name = fullName;
      _role = role;
      notifyListeners();
      return true;
    }

    try {
      final result = await _repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      // With email confirmation OFF, session exists immediately.
      _isLoggedIn = result.hasSession;
      _email = result.email;
      _name = fullName;
      if (_isLoggedIn) {
        await _loadProfile();
        // Ensure display name persisted even if trigger ran first.
        await _repo.upsertProfileName(email: _email, fullName: fullName);
      } else {
        _errorMessage = 'Account created. Check your email to confirm, then sign in.';
      }
      notifyListeners();
      return result.hasSession;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Sign up failed. Check connection and try again.';
      notifyListeners();
      return false;
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
    String chamberName = '',
    String title = '',
    String degree = '',
    String graduatingInstitution = '',
    String graduationYear = '',
    List<String> specialties = const [],
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
    _chamberName = chamberName;
    _title = title;
    _degree = degree;
    _graduatingInstitution = graduatingInstitution;
    _graduationYear = graduationYear;
    _specialties = specialties
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    notifyListeners();

    await _cacheToPrefs();

    if (!useBackend) return;
    if (_repo.userId == null) return;
    try {
      await _repo.updateProfile({
        'full_name': name,
        'specialty': specialty,
        'license_number': licenseNumber,
        'email': email,
        'phone': phone,
        'qualifications': qualifications,
        'experience_years': experienceYears,
        'clinic_address': clinicAddress,
        'bio': bio,
        'chamber_name': chamberName,
        'title': title,
        'degree': degree,
        'graduating_institution': graduatingInstitution,
        'graduation_year': int.tryParse(graduationYear.trim()),
        'specialties': _specialties,
      });
    } catch (_) {
      _errorMessage = 'Profile saved locally, cloud sync failed.';
      notifyListeners();
    }
  }

  /// Step 16: persists the Storage avatar URL to `profiles.avatar_url`.
  /// Returns true on success, false on failure (see [errorMessage]).
  Future<bool> updateAvatarUrl(String url) async {
    _avatarUrl = url;
    notifyListeners();
    await _cacheToPrefs();

    if (!useBackend) return true;
    if (_repo.userId == null) return true;
    try {
      await _repo.updateProfile({'avatar_url': url});
      return true;
    } catch (_) {
      _errorMessage = 'Photo uploaded, profile sync failed.';
      notifyListeners();
      return false;
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
    await prefs.setString(_keyAvatarUrl, _avatarUrl);
    await prefs.setString(_keyChamberName, _chamberName);
    await prefs.setString(_keyTitle, _title);
    await prefs.setString(_keyDegree, _degree);
    await prefs.setString(_keyGraduatingInstitution, _graduatingInstitution);
    await prefs.setString(_keyGraduationYear, _graduationYear);
    await prefs.setStringList(_keySpecialties, _specialties);
    await prefs.setString(_keyVerificationStatus, _verificationStatus);
    await prefs.setString(_keyRejectionReason, _rejectionReason);
    if (_memberSince.isEmpty) {
      _memberSince = _formatDate(DateTime.now());
    }
    await prefs.setString(_keyMemberSince, _memberSince);
  }

  Future<void> logout() async {
    if (useBackend) {
      await _repo.signOut();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);

    _isLoggedIn = false;
    _errorMessage = '';
    notifyListeners();
  }
}
