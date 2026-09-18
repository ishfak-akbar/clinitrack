import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';
import '../models/patient.dart';

/// Step 14: all `patients` data access lives here.
/// Providers hold UI state only and never touch Supabase directly.
class PatientRepository {
  static const String cacheKey = 'patients_list';

  bool get useBackend => SupabaseConfig.isConfigured;

  String? get userId => useBackend
      ? SupabaseConfig.client.auth.currentUser?.id
      : null;

  // ---------- Remote (Supabase) ----------

  Future<List<Patient>> fetchAll() async {
    final rows = await SupabaseConfig.client
        .from('patients')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => Patient.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  Future<Patient> insert(Patient patient, String ownerId) async {
    final row = await SupabaseConfig.client
        .from('patients')
        .insert(patient.toSupabase(ownerId: ownerId))
        .select()
        .single();
    return Patient.fromSupabase(row);
  }

  /// Part 5: linked row for the signed-in patient (`patients.user_id`).
  /// Null when portal migration not run or row not created yet.
  Future<Patient?> fetchMyLinked() async {
    if (!useBackend) return null;
    final uid = userId;
    if (uid == null) return null;
    try {
      final row = await SupabaseConfig.client
          .from('patients')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      if (row == null) return null;
      return Patient.fromSupabase(row);
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String id) async {
    await SupabaseConfig.client.from('patients').delete().eq('id', id);
  }

  // ---------- Local fallback (SharedPreferences) ----------

  Future<List<Patient>> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(cacheKey) ?? [];
    return rawList
        .map((raw) => Patient.fromMap(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveLocal(List<Patient> patients) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = patients.map((p) => jsonEncode(p.toMap())).toList();
    await prefs.setStringList(cacheKey, rawList);
  }
}
