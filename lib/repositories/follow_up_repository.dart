import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';
import '../models/follow_up.dart';

/// Step 14: all `follow_ups` data access lives here.
/// Providers hold UI state only and never touch Supabase directly.
class FollowUpRepository {
  static const String cacheKey = 'follow_ups_list';

  bool get useBackend => SupabaseConfig.isConfigured;

  String? get userId => useBackend
      ? SupabaseConfig.client.auth.currentUser?.id
      : null;

  // ---------- Remote (Supabase) ----------

  Future<List<FollowUp>> fetchAll() async {
    final rows = await SupabaseConfig.client
        .from('follow_ups')
        .select()
        .order('follow_up_date', ascending: true);
    return (rows as List)
        .map((r) => FollowUp.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  Future<FollowUp> insert(FollowUp followUp, String ownerId) async {
    final row = await SupabaseConfig.client
        .from('follow_ups')
        .insert(followUp.toSupabase(ownerId: ownerId))
        .select()
        .single();
    return FollowUp.fromSupabase(row);
  }

  Future<void> updateDone(String id, bool isDone) async {
    await SupabaseConfig.client
        .from('follow_ups')
        .update({'is_done': isDone})
        .eq('id', id);
  }

  Future<void> delete(String id) async {
    await SupabaseConfig.client.from('follow_ups').delete().eq('id', id);
  }

  // ---------- Local fallback (SharedPreferences) ----------

  Future<List<FollowUp>> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(cacheKey) ?? [];
    return rawList
        .map((raw) => FollowUp.fromMap(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveLocal(List<FollowUp> followUps) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = followUps.map((f) => jsonEncode(f.toMap())).toList();
    await prefs.setStringList(cacheKey, rawList);
  }
}
