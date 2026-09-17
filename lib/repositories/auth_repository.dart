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

  /// Doctors directory for patient bookings (Part 5).
  /// RLS (`profiles_doctor_directory`) exposes doctors to signed-in users.
  Future<List<({String id, String name, String specialty})>>
      fetchDoctors() async {
    final rows = await SupabaseConfig.client
        .from('profiles')
        .select('id, full_name, specialty')
        .eq('role', 'Doctor')
        .order('full_name', ascending: true);
    return (rows as List).map((r) {
      final row = r as Map<String, dynamic>;
      return (
        id: row['id'] as String,
        name: ((row['full_name'] as String?) ?? '').trim(),
        specialty: ((row['specialty'] as String?) ?? '').trim(),
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
}
