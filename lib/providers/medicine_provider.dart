import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../repositories/medicine_repository.dart';

export '../models/medicine.dart';

/// Step 14: UI state only — all data access goes through [MedicineRepository].
class MedicineProvider extends ChangeNotifier {
  final MedicineRepository _repo = MedicineRepository();

  List<Medicine> _medicines = [];
  List<MedicineOrder> _orders = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Medicine> get medicines => _medicines;
  List<MedicineOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  bool get useBackend => _repo.useBackend;

  Future<void> loadMedicines() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (useBackend) {
        if (_repo.userId == null) {
          _medicines = [];
          _orders = [];
        } else {
          _medicines = await _repo.fetchAll();
          try {
            _orders = await _repo.fetchOrders();
          } catch (_) {
            // Order history is non-fatal — inventory still works.
            _orders = [];
          }
        }
      } else {
        _medicines = await _repo.loadLocal();
        _orders = await _repo.loadLocalOrders();
      }
    } catch (_) {
      _errorMessage =
          'Could not load medicines. Check connection and try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Adds a new medicine to the inventory (used to populate an empty list).
  Future<bool> addMedicine(Medicine medicine) async {
    _errorMessage = '';
    if (useBackend) {
      final userId = _repo.userId;
      if (userId == null) {
        _errorMessage = 'Please sign in again to add a medicine.';
        notifyListeners();
        return false;
      }
      try {
        final saved = await _repo.insert(medicine, userId);
        _medicines.add(saved);
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
    await _repo.saveLocal(_medicines, _orders);
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
      final userId = _repo.userId;
      if (userId == null) {
        _errorMessage = 'Please sign in again.';
        notifyListeners();
        return false;
      }
      try {
        final newStock = current.stock + quantity;
        await _repo.updateStock(id, newStock);
        // Record order history (non-fatal if it fails).
        try {
          final order = await _repo.insertOrder(
            ownerId: userId,
            medicineId: id,
            medicineName: current.name,
            quantity: quantity,
          );
          _orders.insert(0, order);
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
    await _repo.saveLocal(_medicines, _orders);
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
}
