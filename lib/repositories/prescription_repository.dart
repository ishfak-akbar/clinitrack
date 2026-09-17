import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';
import '../models/prescription.dart';

/// Step 14: all `prescriptions` data access lives here.
/// Providers hold UI state only and never touch Supabase directly.
class PrescriptionRepository {
  static const String cacheKey = 'prescriptions_list';

  bool get useBackend => SupabaseConfig.isConfigured;

  String? get userId => useBackend
      ? SupabaseConfig.client.auth.currentUser?.id
      : null;

  // ---------- Remote (Supabase) ----------

  Future<List<Prescription>> fetchAll() async {
    final rows = await SupabaseConfig.client
        .from('prescriptions')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => Prescription.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  Future<Prescription> insert(
      Prescription prescription, String ownerId) async {
    final row = await SupabaseConfig.client
        .from('prescriptions')
        .insert(prescription.toSupabase(ownerId: ownerId))
        .select()
        .single();
    return Prescription.fromSupabase(row);
  }

  Future<void> delete(String id) async {
    await SupabaseConfig.client.from('prescriptions').delete().eq('id', id);
  }

  // ---------- Local fallback (SharedPreferences) ----------

  Future<List<Prescription>> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(cacheKey) ?? [];
    return rawList
        .map((raw) => Prescription.fromMap(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveLocal(List<Prescription> prescriptions) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prescriptions.map((p) => jsonEncode(p.toMap())).toList();
    await prefs.setStringList(cacheKey, rawList);
  }
}
