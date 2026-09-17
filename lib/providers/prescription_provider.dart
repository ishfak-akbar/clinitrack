import 'package:flutter/material.dart';

import '../models/prescription.dart';
import '../repositories/prescription_repository.dart';

export '../models/prescription.dart';

/// Step 14: UI state only — all data access goes through [PrescriptionRepository].
class PrescriptionProvider extends ChangeNotifier {
  final PrescriptionRepository _repo = PrescriptionRepository();

  List<Prescription> _prescriptions = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Prescription> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  bool get useBackend => _repo.useBackend;

  List<Prescription> forPatient(String patientId) =>
      _prescriptions.where((p) => p.patientId == patientId).toList();

  Future<void> loadPrescriptions() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (useBackend) {
        if (_repo.userId == null) {
          _prescriptions = [];
        } else {
          _prescriptions = await _repo.fetchAll();
        }
      } else {
        _prescriptions = await _repo.loadLocal();
      }
    } catch (_) {
      _errorMessage =
          'Could not load prescriptions. Check connection and try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addPrescription(Prescription prescription) async {
    _errorMessage = '';
    if (useBackend) {
      final userId = _repo.userId;
      if (userId == null) {
        _errorMessage = 'Please sign in again to add a prescription.';
        notifyListeners();
        return false;
      }
      try {
        final saved = await _repo.insert(prescription, userId);
        _prescriptions.insert(0, saved);
        notifyListeners();
        return true;
      } catch (_) {
        _errorMessage =
            'Could not save prescription. Check connection and try again.';
        notifyListeners();
        return false;
      }
    }

    _prescriptions.insert(
      0,
      prescription.id.isEmpty
          ? Prescription(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              patientId: prescription.patientId,
              medicineName: prescription.medicineName,
              dosage: prescription.dosage,
              duration: prescription.duration,
              frequency: prescription.frequency,
              notes: prescription.notes,
            )
          : prescription,
    );
    notifyListeners();
    await _repo.saveLocal(_prescriptions);
    return true;
  }

  Future<bool> deletePrescription(String id) async {
    _errorMessage = '';
    if (useBackend) {
      if (_repo.userId == null) {
        _errorMessage = 'Please sign in again.';
        notifyListeners();
        return false;
      }
      try {
        await _repo.delete(id);
        _prescriptions.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      } catch (_) {
        _errorMessage = 'Could not delete prescription. Try again.';
        notifyListeners();
        return false;
      }
    }

    _prescriptions.removeWhere((p) => p.id == id);
    notifyListeners();
    await _repo.saveLocal(_prescriptions);
    return true;
  }

  /// Clears in-memory list (e.g. on logout so the next account
  /// never briefly sees the previous account's prescriptions).
  void clearCache() {
    _prescriptions = [];
    _errorMessage = '';
    notifyListeners();
  }
}
