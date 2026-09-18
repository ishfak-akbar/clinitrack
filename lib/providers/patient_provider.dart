import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../repositories/patient_repository.dart';

export '../models/patient.dart';

/// Step 14: UI state only — all data access goes through [PatientRepository].
class PatientProvider extends ChangeNotifier {
  final PatientRepository _repo = PatientRepository();

  List<Patient> _patients = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Patient> get patients => _patients;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  bool get useBackend => _repo.useBackend;

  /// Part 5: own linked row for patient accounts (first of visible rows).
  Patient? get myLinked => _patients.isEmpty ? null : _patients.first;

  Future<Patient?> fetchMyLinked() async {
    final linked = await _repo.fetchMyLinked();
    if (linked != null && !_patients.any((p) => p.id == linked.id)) {
      _patients = [linked, ..._patients];
      notifyListeners();
    }
    return linked ?? myLinked;
  }

  Future<void> loadPatients() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (useBackend) {
        final userId = _repo.userId;
        if (userId == null) {
          _patients = [];
        } else {
          _patients = await _repo.fetchAll();
        }
      } else {
        _patients = await _repo.loadLocal();
      }
    } catch (_) {
      _errorMessage = 'Could not load patients. Check connection and try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addPatient(Patient patient) async {
    _errorMessage = '';
    if (useBackend) {
      final userId = _repo.userId;
      if (userId == null) {
        _errorMessage = 'Please sign in again to add a patient.';
        notifyListeners();
        return false;
      }
      try {
        final saved = await _repo.insert(patient, userId);
        _patients.insert(0, saved);
        notifyListeners();
        return true;
      } catch (_) {
        _errorMessage = 'Could not save patient. Check connection and try again.';
        notifyListeners();
        return false;
      }
    }

    final local = Patient(
      id: patient.id.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : patient.id,
      name: patient.name,
      age: patient.age,
      gender: patient.gender,
      contact: patient.contact,
      bloodGroup: patient.bloodGroup,
      medicalHistory: patient.medicalHistory,
      allergies: patient.allergies,
      lastVisit: patient.lastVisit.isEmpty
          ? Patient.formatDisplayDate(DateTime.now())
          : patient.lastVisit,
    );
    _patients.insert(0, local);
    notifyListeners();
    await _repo.saveLocal(_patients);
    return true;
  }

  Future<bool> deletePatient(String id) async {
    _errorMessage = '';
    if (useBackend) {
      if (_repo.userId == null) {
        _errorMessage = 'Please sign in again.';
        notifyListeners();
        return false;
      }
      try {
        await _repo.delete(id);
        _patients.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      } catch (_) {
        _errorMessage = 'Could not delete patient. Try again.';
        notifyListeners();
        return false;
      }
    }

    _patients.removeWhere((p) => p.id == id);
    notifyListeners();
    await _repo.saveLocal(_patients);
    return true;
  }

  /// Clears in-memory list (e.g. on logout so the next account
  /// never briefly sees the previous account's patients).
  void clearCache() {
    _patients = [];
    _errorMessage = '';
    notifyListeners();
  }
}
