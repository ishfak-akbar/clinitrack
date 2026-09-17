import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';
import '../models/appointment.dart';

/// Step 14: all `appointments` data access lives here.
/// Providers hold UI state only and never touch Supabase directly.
class AppointmentRepository {
  static const String cacheKey = 'appointments_list';

  bool get useBackend => SupabaseConfig.isConfigured;

  String? get userId => useBackend
      ? SupabaseConfig.client.auth.currentUser?.id
      : null;

  // ---------- Remote (Supabase) ----------

  Future<List<Appointment>> fetchAll() async {
    final rows = await SupabaseConfig.client
        .from('appointments')
        .select()
        .order('date_iso', ascending: true);
    return (rows as List)
        .map((r) => Appointment.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  Future<Appointment> insert(Appointment appointment, String ownerId) async {
    final row = await SupabaseConfig.client
        .from('appointments')
        .insert(appointment.toSupabase(ownerId: ownerId))
        .select()
        .single();
    return Appointment.fromSupabase(row);
  }

  Future<void> updateStatus(String id, String status) async {
    await SupabaseConfig.client
        .from('appointments')
        .update({'status': status})
        .eq('id', id);
  }

  // ---------- Local fallback (SharedPreferences) ----------

  Future<List<Appointment>> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(cacheKey) ?? [];
    return rawList
        .map((raw) => Appointment.fromMap(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveLocal(List<Appointment> appointments) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = appointments.map((a) => jsonEncode(a.toMap())).toList();
    await prefs.setStringList(cacheKey, rawList);
  }
}
