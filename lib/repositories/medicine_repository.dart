import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';
import '../models/medicine.dart';

/// Step 14: all `medicines` + `medicine_orders` data access lives here.
/// Providers hold UI state only and never touch Supabase directly.
class MedicineRepository {
  static const String cacheKey = 'medicines_list';
  static const String ordersCacheKey = 'medicine_orders_list';

  bool get useBackend => SupabaseConfig.isConfigured;

  String? get userId => useBackend
      ? SupabaseConfig.client.auth.currentUser?.id
      : null;

  // ---------- Remote (Supabase) ----------

  Future<List<Medicine>> fetchAll() async {
    final rows = await SupabaseConfig.client
        .from('medicines')
        .select()
        .order('name', ascending: true);
    return (rows as List)
        .map((r) => Medicine.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<MedicineOrder>> fetchOrders() async {
    final rows = await SupabaseConfig.client
        .from('medicine_orders')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    return (rows as List)
        .map((r) => MedicineOrder.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  Future<Medicine> insert(Medicine medicine, String ownerId) async {
    final row = await SupabaseConfig.client
        .from('medicines')
        .insert(medicine.toSupabase(ownerId: ownerId))
        .select()
        .single();
    return Medicine.fromSupabase(row);
  }

  Future<void> updateStock(String id, int stock) async {
    await SupabaseConfig.client
        .from('medicines')
        .update({'stock': stock})
        .eq('id', id);
  }

  Future<MedicineOrder> insertOrder({
    required String ownerId,
    required String medicineId,
    required String medicineName,
    required int quantity,
  }) async {
    final row = await SupabaseConfig.client
        .from('medicine_orders')
        .insert({
          'owner_id': ownerId,
          'medicine_id': medicineId,
          'medicine_name': medicineName,
          'quantity': quantity,
        })
        .select()
        .single();
    return MedicineOrder.fromSupabase(row);
  }

  // ---------- Local fallback (SharedPreferences) ----------

  Future<List<Medicine>> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(cacheKey) ?? [];
    return rawList
        .map((raw) => Medicine.fromMap(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  Future<List<MedicineOrder>> loadLocalOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(ordersCacheKey) ?? [];
    return rawList
        .map((raw) => MedicineOrder.fromMap(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveLocal(
      List<Medicine> medicines, List<MedicineOrder> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        cacheKey, medicines.map((m) => jsonEncode(m.toMap())).toList());
    await prefs.setStringList(
        ordersCacheKey, orders.map((o) => jsonEncode(o.toMap())).toList());
  }
}
