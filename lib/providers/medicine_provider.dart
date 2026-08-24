import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Medicine {
  final String id;
  final String name;
  final String category;
  final int stock;
  final String unit;

  Medicine({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.unit,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'stock': stock,
    'unit': unit,
  };

  factory Medicine.fromMap(Map<String, dynamic> map) => Medicine(
    id: map['id'] as String,
    name: map['name'] as String,
    category: map['category'] as String,
    stock: map['stock'] as int,
    unit: map['unit'] as String,
  );

  Medicine copyWith({int? stock}) => Medicine(
    id: id,
    name: name,
    category: category,
    stock: stock ?? this.stock,
    unit: unit,
  );
}

class MedicineProvider extends ChangeNotifier {
  static const String _key = 'medicines_list';

  List<Medicine> _medicines = [];

  List<Medicine> get medicines => _medicines;

  static final List<Medicine> _seed = [
    Medicine(id: 'm1', name: 'Paracetamol 500mg', category: 'Pain Relief', stock: 120, unit: 'tablets'),
    Medicine(id: 'm2', name: 'Amoxicillin 250mg', category: 'Antibiotic', stock: 45, unit: 'capsules'),
    Medicine(id: 'm3', name: 'Omeprazole 20mg', category: 'Gastric', stock: 80, unit: 'tablets'),
    Medicine(id: 'm4', name: 'Cetirizine 10mg', category: 'Allergy', stock: 60, unit: 'tablets'),
    Medicine(id: 'm5', name: 'Metformin 500mg', category: 'Diabetes', stock: 30, unit: 'tablets'),
    Medicine(id: 'm6', name: 'Vitamin D3', category: 'Supplement', stock: 25, unit: 'tablets'),
  ];

  Future<void> loadMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key);

    if (rawList == null) {
      _medicines = List.from(_seed);
      await _persist();
    } else {
      _medicines = rawList
          .map((raw) => Medicine.fromMap(jsonDecode(raw) as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  Future<void> addStock(String id, int quantity) async {
    final index = _medicines.indexWhere((m) => m.id == id);
    if (index == -1) return;

    _medicines[index] = _medicines[index].copyWith(
      stock: _medicines[index].stock + quantity,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _medicines.map((m) => jsonEncode(m.toMap())).toList();
    await prefs.setStringList(_key, rawList);
  }
}