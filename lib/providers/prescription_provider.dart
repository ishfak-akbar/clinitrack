import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';

class Prescription {
  final String id; // uuid from Supabase, or local millis key in fallback mode
  final String patientId;
  final String medicineName;
  final String dosage;
  final String duration;
  final String frequency;
  final String notes;

  // Step 11/12: backend identity + timestamps (null in local fallback mode).
  final String? ownerId;
  final DateTime? createdAt;

  Prescription({
    required this.id,
    required this.patientId,
    required this.medicineName,
    required this.dosage,
    required this.duration,
    required this.frequency,
    required this.notes,
    this.ownerId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'patientId': patientId,
    'medicineName': medicineName,
    'dosage': dosage,
    'duration': duration,
    'frequency': frequency,
    'notes': notes,
    'ownerId': ownerId,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory Prescription.fromMap(Map<String, dynamic> map) => Prescription(
    id: map['id'] as String,
    patientId: (map['patientId'] ?? '') as String,
    medicineName: (map['medicineName'] ?? '') as String,
    dosage: (map['dosage'] ?? '') as String,
    duration: (map['duration'] ?? '') as String,
    frequency: (map['frequency'] ?? 'Daily') as String,
    notes: (map['notes'] ?? '') as String,
    ownerId: map['ownerId'] as String?,
    createdAt: map['createdAt'] == null
        ? null
        : DateTime.tryParse(map['createdAt'] as String),
  );

  /// Row from `public.prescriptions` -> UI model.
  /// DB columns: patient_id uuid?, medicine_name, dosage, duration_text,
  /// frequency, notes, owner_id, created_at.
  factory Prescription.fromSupabase(Map<String, dynamic> row) => Prescription(
    id: row['id'] as String,
    ownerId: row['owner_id'] as String?,
    patientId: (row['patient_id'] ?? '') as String,
    medicineName: (row['medicine_name'] ?? '') as String,
    dosage: (row['dosage'] ?? '') as String,
    duration: (row['duration_text'] ?? '') as String,
    frequency: (row['frequency'] ?? 'Daily') as String,
    notes: (row['notes'] ?? '') as String,
    createdAt: row['created_at'] == null
        ? null
        : DateTime.tryParse(row['created_at'] as String),
  );

  /// UI model -> `public.prescriptions` insert payload.
  /// `id` omitted so Postgres assigns `gen_random_uuid()`.
  /// `patient_id` sent only when it is a real uuid (FK to patients);
  /// legacy local ids are dropped to null.
  Map<String, dynamic> toSupabase({required String ownerId}) => {
    'owner_id': ownerId,
    'patient_id': isUuid(patientId) ? patientId : null,
    'medicine_name': medicineName.trim(),
    'dosage': dosage,
    'duration_text': duration,
    'frequency': frequency.isEmpty ? 'Daily' : frequency,
    'notes': notes,
  };

  static bool isUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  String get summary => '$medicineName $dosage — $frequency, $duration';
}

class PrescriptionProvider extends ChangeNotifier {
  static const String _key = 'prescriptions_list';

  List<Prescription> _prescriptions = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Prescription> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  bool get useBackend => SupabaseConfig.isConfigured;
  String? get _userId => useBackend
      ? SupabaseConfig.client.auth.currentUser?.id
      : null;

  List<Prescription> forPatient(String patientId) =>
      _prescriptions.where((p) => p.patientId == patientId).toList();

  Future<void> loadPrescriptions() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (useBackend) {
        await _loadFromSupabase();
      } else {
        await _loadLocal();
      }
    } catch (_) {
      _errorMessage =
          'Could not load prescriptions. Check connection and try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromSupabase() async {
    final userId = _userId;
    if (userId == null) {
      _prescriptions = [];
      return;
    }
    final rows = await SupabaseConfig.client
        .from('prescriptions')
        .select()
        .order('created_at', ascending: false);
    _prescriptions = (rows as List)
        .map((r) => Prescription.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  /// Local fallback when Supabase is not configured (fresh clone / offline).
  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];
    _prescriptions = rawList
        .map((raw) => Prescription.fromMap(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  Future<bool> addPrescription(Prescription prescription) async {
    _errorMessage = '';
    if (useBackend) {
      final userId = _userId;
      if (userId == null) {
        _errorMessage = 'Please sign in again to add a prescription.';
        notifyListeners();
        return false;
      }
      try {
        final row = await SupabaseConfig.client
            .from('prescriptions')
            .insert(prescription.toSupabase(ownerId: userId))
            .select()
            .single();
        _prescriptions.insert(0, Prescription.fromSupabase(row));
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
    await _persistLocal();
    return true;
  }

  Future<bool> deletePrescription(String id) async {
    _errorMessage = '';
    if (useBackend) {
      final userId = _userId;
      if (userId == null) {
        _errorMessage = 'Please sign in again.';
        notifyListeners();
        return false;
      }
      try {
        await SupabaseConfig.client.from('prescriptions').delete().eq('id', id);
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
    await _persistLocal();
    return true;
  }

  /// Clears in-memory list (e.g. on logout so the next account
  /// never briefly sees the previous account's prescriptions).
  void clearCache() {
    _prescriptions = [];
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _prescriptions.map((p) => jsonEncode(p.toMap())).toList();
    await prefs.setStringList(_key, rawList);
  }
}
