import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';

class Medicine {
  final String id; // uuid from Supabase, or local millis key in fallback mode
  final String name;
  final String category;
  final int stock;
  final String unit;

  // Step 11/12: backend identity + timestamps (null in local fallback mode).
  final String? ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Medicine({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.unit,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'stock': stock,
    'unit': unit,
    'ownerId': ownerId,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Medicine.fromMap(Map<String, dynamic> map) => Medicine(
    id: map['id'] as String,
    name: (map['name'] ?? '') as String,
    category: (map['category'] ?? 'General') as String,
    stock: (map['stock'] as num? ?? 0).toInt(),
    unit: (map['unit'] ?? 'tablets') as String,
    ownerId: map['ownerId'] as String?,
    createdAt: map['createdAt'] == null
        ? null
        : DateTime.tryParse(map['createdAt'] as String),
    updatedAt: map['updatedAt'] == null
        ? null
        : DateTime.tryParse(map['updatedAt'] as String),
  );

  /// Row from `public.medicines` -> UI model.
  factory Medicine.fromSupabase(Map<String, dynamic> row) => Medicine(
    id: row['id'] as String,
    ownerId: row['owner_id'] as String?,
    name: (row['name'] ?? '') as String,
    category: (row['category'] ?? 'General') as String,
    stock: (row['stock'] as num? ?? 0).toInt(),
    unit: (row['unit'] ?? 'tablets') as String,
    createdAt: row['created_at'] == null
        ? null
        : DateTime.tryParse(row['created_at'] as String),
    updatedAt: row['updated_at'] == null
        ? null
        : DateTime.tryParse(row['updated_at'] as String),
  );

  /// UI model -> `public.medicines` insert payload.
  /// `id` omitted so Postgres assigns `gen_random_uuid()`.
  /// `unique(owner_id, name)` is enforced in Postgres.
  Map<String, dynamic> toSupabase({required String ownerId}) => {
    'owner_id': ownerId,
    'name': name.trim(),
    'category': category.isEmpty ? 'General' : category,
    'stock': stock < 0 ? 0 : stock,
    'unit': unit.isEmpty ? 'tablets' : unit,
  };

  Medicine copyWith({int? stock}) => Medicine(
    id: id,
    name: name,
    category: category,
    stock: stock ?? this.stock,
    unit: unit,
    ownerId: ownerId,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

class MedicineOrder {
  final String id;
  final String? medicineId;
  final String medicineName;
  final int quantity;

  final String? ownerId;
  final DateTime? createdAt;

  MedicineOrder({
    required this.id,
    this.medicineId,
    required this.medicineName,
    required this.quantity,
    this.ownerId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'medicineId': medicineId,
    'medicineName': medicineName,
    'quantity': quantity,
    'ownerId': ownerId,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory MedicineOrder.fromMap(Map<String, dynamic> map) => MedicineOrder(
    id: map['id'] as String,
    medicineId: map['medicineId'] as String?,
    medicineName: (map['medicineName'] ?? '') as String,
    quantity: (map['quantity'] as num? ?? 0).toInt(),
    ownerId: map['ownerId'] as String?,
    createdAt: map['createdAt'] == null
        ? null
        : DateTime.tryParse(map['createdAt'] as String),
  );

  /// Row from `public.medicine_orders` -> UI model.
  factory MedicineOrder.fromSupabase(Map<String, dynamic> row) =>
      MedicineOrder(
        id: row['id'] as String,
        medicineId: row['medicine_id'] as String?,
        medicineName: (row['medicine_name'] ?? '') as String,
        quantity: (row['quantity'] as num? ?? 0).toInt(),
        ownerId: row['owner_id'] as String?,
        createdAt: row['created_at'] == null
            ? null
            : DateTime.tryParse(row['created_at'] as String),
      );
}

class MedicineProvider extends ChangeNotifier {
  static const String _key = 'medicines_list';
  static const String _ordersKey = 'medicine_orders_list';

  List<Medicine> _medicines = [];
  List<MedicineOrder> _orders = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Medicine> get medicines => _medicines;
  List<MedicineOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  bool get useBackend => SupabaseConfig.isConfigured;
  String? get _userId => useBackend
      ? SupabaseConfig.client.auth.currentUser?.id
      : null;

  Future<void> loadMedicines() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (useBackend) {
        await _loadFromSupabase();
        await _loadOrdersFromSupabase();
      } else {
        await _loadLocal();
      }
    } catch (_) {
      _errorMessage =
          'Could not load medicines. Check connection and try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromSupabase() async {
    final userId = _userId;
    if (userId == null) {
      _medicines = [];
      return;
    }
    final rows = await SupabaseConfig.client
        .from('medicines')
        .select()
        .order('name', ascending: true);
    _medicines = (rows as List)
        .map((r) => Medicine.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> _loadOrdersFromSupabase() async {
    final userId = _userId;
    if (userId == null) {
      _orders = [];
      return;
    }
    try {
      final rows = await SupabaseConfig.client
          .from('medicine_orders')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      _orders = (rows as List)
          .map((r) => MedicineOrder.fromSupabase(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Order history is non-fatal — inventory still works.
      _orders = [];
    }
  }

  /// Local fallback when Supabase is not configured (fresh clone / offline).
  /// Starts empty — the old demo seeds were dropped in Step 11.
  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];
    _medicines = rawList
        .map((raw) => Medicine.fromMap(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
    final rawOrders = prefs.getStringList(_ordersKey) ?? [];
    _orders = rawOrders
        .map((raw) => MedicineOrder.fromMap(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  /// Adds a new medicine to the inventory (used to populate an empty list).
  Future<bool> addMedicine(Medicine medicine) async {
    _errorMessage = '';
    if (useBackend) {
      final userId = _userId;
      if (userId == null) {
        _errorMessage = 'Please sign in again to add a medicine.';
        notifyListeners();
        return false;
      }
      try {
        final row = await SupabaseConfig.client
            .from('medicines')
            .insert(medicine.toSupabase(ownerId: userId))
            .select()
            .single();
        _medicines.add(Medicine.fromSupabase(row));
        _medicines.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
        return true;
      } catch (_) {
        _errorMessage =
            'Could not save medicine. It may already exist — try ordering stock instead.';
        notifyListeners();
        return false;
      }
    }

    _medicines.add(
      medicine.id.isEmpty
          ? Medicine(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: medicine.name,
              category: medicine.category,
              stock: medicine.stock,
              unit: medicine.unit,
            )
          : medicine,
    );
    _medicines.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    await _persistLocal();
    return true;
  }

  /// Increases stock for [id] by [quantity] and records the order history.
  Future<bool> addStock(String id, int quantity) async {
    _errorMessage = '';
    if (quantity <= 0) {
      _errorMessage = 'Enter a valid quantity.';
      notifyListeners();
      return false;
    }
    final index = _medicines.indexWhere((m) => m.id == id);
    if (index == -1) return false;
    final current = _medicines[index];

    if (useBackend) {
      final userId = _userId;
      if (userId == null) {
        _errorMessage = 'Please sign in again.';
        notifyListeners();
        return false;
      }
      try {
        final newStock = current.stock + quantity;
        await SupabaseConfig.client
            .from('medicines')
            .update({'stock': newStock})
            .eq('id', id);
        // Record order history (non-fatal if it fails).
        try {
          final orderRow = await SupabaseConfig.client
              .from('medicine_orders')
              .insert({
                'owner_id': userId,
                'medicine_id': id,
                'medicine_name': current.name,
                'quantity': quantity,
              })
              .select()
              .single();
          _orders.insert(0, MedicineOrder.fromSupabase(orderRow));
        } catch (_) {
          // Stock was updated — keep going.
        }
        _medicines[index] = current.copyWith(stock: newStock);
        notifyListeners();
        return true;
      } catch (_) {
        _errorMessage = 'Could not update stock. Try again.';
        notifyListeners();
        return false;
      }
    }

    _medicines[index] = _medicines[index].copyWith(
      stock: _medicines[index].stock + quantity,
    );
    _orders.insert(
      0,
      MedicineOrder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        medicineId: id,
        medicineName: current.name,
        quantity: quantity,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    await _persistLocal();
    return true;
  }

  /// Clears in-memory lists (e.g. on logout so the next account
  /// never briefly sees the previous account's inventory).
  void clearCache() {
    _medicines = [];
    _orders = [];
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _medicines.map((m) => jsonEncode(m.toMap())).toList();
    await prefs.setStringList(_key, rawList);
    final rawOrders = _orders.map((o) => jsonEncode(o.toMap())).toList();
    await prefs.setStringList(_ordersKey, rawOrders);
  }
}
