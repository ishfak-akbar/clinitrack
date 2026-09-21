import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Thrown by [AuthRepository] for auth/profile failures with a
/// user-presentable [message]. Providers catch this instead of
/// importing Supabase types themselves.
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

/// Step 14: all Supabase auth + `profiles` data access lives here.
class AuthRepository {
  bool get useBackend => SupabaseConfig.isConfigured;

  String? get userId => useBackend
      ? SupabaseConfig.client.auth.currentUser?.id
      : null;

  String get currentEmail =>
      SupabaseConfig.client.auth.currentUser?.email ?? '';

  bool get hasSession =>
      SupabaseConfig.client.auth.currentSession?.user != null;

  Future<({String email, bool hasSession})> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.session == null) {
        throw const AuthFailure('Sign in failed. Please try again.');
      }
      return (email: res.user?.email ?? email, hasSession: true);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
          'Sign in failed. Check connection and try again.');
    }
  }

  /// Returns `(email, hasSession)`. `hasSession` is false when email
  /// confirmation is ON — the account exists but the user must confirm first.
  Future<({String email, bool hasSession})> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'Doctor',
  }) async {
    final safeRole = role == 'Patient' ? 'Patient' : 'Doctor';
    try {
      final res = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': safeRole},
      );
      final user = res.user;
      if (user == null) {
        throw const AuthFailure('Sign up failed. Please try again.');
      }
      return (email: user.email ?? email, hasSession: res.session != null);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
          'Sign up failed. Check connection and try again.');
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (_) {
      // Caller still logs out locally.
    }
  }

  /// Doctors directory for patient bookings (Part 5; step 4: approved only).
  /// RLS (`profiles_doctor_directory`) already exposes approved doctors to
  /// signed-in users; the explicit filter below is belt-and-suspenders so a
  /// pending profile can never leak through a policy misconfiguration.
  /// Includes profile + verification fields so patients see a rich card.
  Future<List<DoctorDirectoryEntry>> fetchDoctors() async {
    // Offline / local mode: repository has no backend — caller shows
    // demo directory instead of failing.
    if (!useBackend) return [];
    final rows = await SupabaseConfig.client
        .from('profiles')
        .select(
            'id, full_name, specialty, avatar_url, qualifications, experience_years, clinic_address, bio, '
            'title, chamber_name, degree, graduating_institution, graduation_year, specialties')
        .eq('role', 'Doctor')
        .eq('verification_status', 'approved')
        .order('full_name', ascending: true);
    return (rows as List).map((r) {
      final row = r as Map<String, dynamic>;
      final gradYear = row['graduation_year'];
      return DoctorDirectoryEntry(
        id: (row['id'] as String?) ?? '',
        name: ((row['full_name'] as String?) ?? '').trim(),
        specialty: ((row['specialty'] as String?) ?? '').trim(),
        avatarUrl: ((row['avatar_url'] as String?) ?? '').trim(),
        qualifications: ((row['qualifications'] as String?) ?? '').trim(),
        experienceYears: ((row['experience_years'] as String?) ?? '').trim(),
        clinicAddress: ((row['clinic_address'] as String?) ?? '').trim(),
        bio: ((row['bio'] as String?) ?? '').trim(),
        title: ((row['title'] as String?) ?? '').trim(),
        chamberName: ((row['chamber_name'] as String?) ?? '').trim(),
        degree: ((row['degree'] as String?) ?? '').trim(),
        graduatingInstitution:
            ((row['graduating_institution'] as String?) ?? '').trim(),
        graduationYear: gradYear == null ? '' : gradYear.toString(),
        specialties: (row['specialties'] as List?)
                ?.map((e) => e.toString())
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList() ??
            const [],
      );
    }).toList();
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return null;
    try {
      return await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (_) {
      // Table/RLS not ready yet — caller stays logged in with auth email only.
      return null;
    }
  }

  /// Ensures the display name is persisted even if the signup trigger
  /// already created the row (upsert is idempotent).
  Future<void> upsertProfileName({
    required String email,
    required String fullName,
  }) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    try {
      await SupabaseConfig.client.from('profiles').upsert({
        'id': user.id,
        'email': email,
        'full_name': fullName,
      });
    } catch (_) {
      // Non-fatal — trigger already created the row.
    }
  }

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    await SupabaseConfig.client
        .from('profiles')
        .update(fields)
        .eq('id', user.id);
  }

  /// Step 5: pending doctor applications for the admin review queue.
  /// RLS (`profiles_admin_read`) restricts this to admins; the call throws
  /// [AuthFailure] otherwise (or on connection failure).
  Future<List<DoctorApplicationEntry>> fetchPendingDoctors() async {
    if (!useBackend) return [];
    try {
      final rows = await SupabaseConfig.client
          .from('profiles')
          .select(
              'id, full_name, email, title, degree, graduating_institution, '
              'graduation_year, license_number, chamber_name, clinic_address, '
              'phone, qualifications, experience_years, specialty, specialties, '
              'bio, created_at')
          .eq('role', 'Doctor')
          .eq('verification_status', 'pending')
          .order('created_at', ascending: true);
      return (rows as List).map((r) {
        final row = r as Map<String, dynamic>;
        final gradYear = row['graduation_year'];
        DateTime? createdAt;
        final rawCreated = row['created_at'];
        if (rawCreated != null) {
          createdAt = DateTime.tryParse(rawCreated.toString());
        }
        return DoctorApplicationEntry(
          id: (row['id'] as String?) ?? '',
          name: ((row['full_name'] as String?) ?? '').trim(),
          email: ((row['email'] as String?) ?? '').trim(),
          title: ((row['title'] as String?) ?? '').trim(),
          degree: ((row['degree'] as String?) ?? '').trim(),
          graduatingInstitution:
              ((row['graduating_institution'] as String?) ?? '').trim(),
          graduationYear: gradYear == null ? '' : gradYear.toString(),
          licenseNumber: ((row['license_number'] as String?) ?? '').trim(),
          chamberName: ((row['chamber_name'] as String?) ?? '').trim(),
          clinicAddress: ((row['clinic_address'] as String?) ?? '').trim(),
          phone: ((row['phone'] as String?) ?? '').trim(),
          qualifications: ((row['qualifications'] as String?) ?? '').trim(),
          experienceYears: ((row['experience_years'] as String?) ?? '').trim(),
          specialty: ((row['specialty'] as String?) ?? '').trim(),
          specialties: (row['specialties'] as List?)
                  ?.map((e) => e.toString())
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList() ??
              const [],
          bio: ((row['bio'] as String?) ?? '').trim(),
          createdAt: createdAt,
        );
      }).toList();
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const AuthFailure(
          'Could not load applications. Check connection and try again.');
    }
  }

  /// Step 5: admin verdict on one application. RLS + the
  /// `prevent_self_verification()` trigger enforce the admin-only rule;
  /// rejections require a reason (shown to the doctor on resubmit).
  Future<void> reviewDoctor({
    required String id,
    required bool approve,
    String reason = '',
  }) async {
    final uid = userId;
    if (uid == null) {
      throw const AuthFailure('Please sign in again.');
    }
    if (!approve && reason.trim().isEmpty) {
      throw const AuthFailure(
          'A reason is required — the doctor will see it.');
    }
    try {
      await SupabaseConfig.client.from('profiles').update({
        'verification_status': approve ? 'approved' : 'rejected',
        'reviewed_by': uid,
        'reviewed_at': DateTime.now().toIso8601String(),
        'rejection_reason': approve ? '' : reason.trim(),
      }).eq('id', id);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const AuthFailure(
          'Could not save review. Check connection and try again.');
    }
  }
}

/// One pending doctor application in the admin review queue (step 5).
class DoctorApplicationEntry {
  final String id; // profile id == auth user id
  final String name;
  final String email;
  final String title;
  final String degree;
  final String graduatingInstitution;
  final String graduationYear;
  final String licenseNumber;
  final String chamberName;
  final String clinicAddress;
  final String phone;
  final String qualifications;
  final String experienceYears;
  final String specialty;
  final List<String> specialties;
  final String bio;
  final DateTime? createdAt;

  const DoctorApplicationEntry({
    required this.id,
    required this.name,
    this.email = '',
    this.title = '',
    this.degree = '',
    this.graduatingInstitution = '',
    this.graduationYear = '',
    this.licenseNumber = '',
    this.chamberName = '',
    this.clinicAddress = '',
    this.phone = '',
    this.qualifications = '',
    this.experienceYears = '',
    this.specialty = '',
    this.specialties = const [],
    this.bio = '',
    this.createdAt,
  });

  /// Display line: stored array first, legacy single column as fallback.
  String get specialtyLine =>
      specialties.isNotEmpty ? specialties.join(', ') : specialty;

  String get appliedLabel {
    if (createdAt == null) return '';
    final d = createdAt!.toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }
}

/// One row of the doctors directory shown to patients.
class DoctorDirectoryEntry {
  final String id;
  final String name;
  final String specialty;
  final String avatarUrl;
  final String qualifications;
  final String experienceYears;
  final String clinicAddress;
  final String bio;

  /// Step 4 (verification): credential fields for richer patient-side cards.
  final String title;
  final String chamberName;
  final String degree;
  final String graduatingInstitution;
  final String graduationYear;
  final List<String> specialties;

  const DoctorDirectoryEntry({
    required this.id,
    required this.name,
    this.specialty = '',
    this.avatarUrl = '',
    this.qualifications = '',
    this.experienceYears = '',
    this.clinicAddress = '',
    this.bio = '',
    this.title = '',
    this.chamberName = '',
    this.degree = '',
    this.graduatingInstitution = '',
    this.graduationYear = '',
    this.specialties = const [],
  });

  /// Display line: stored array first, legacy single column as fallback.
  String get specialtyLine =>
      specialties.isNotEmpty ? specialties.join(', ') : specialty;
}
