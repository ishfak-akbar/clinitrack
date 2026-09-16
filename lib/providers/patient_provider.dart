import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';

class Patient {
  final String id; // uuid from Supabase, or local millis key in fallback mode
  final String name;
  final String age;
  final String gender;
  final String contact;
  final String bloodGroup;
  final String medicalHistory;
  final List<String> allergies;
  final String lastVisit;

  // Step 9/12: backend identity + timestamps (null in local fallback mode).
  final String? ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.bloodGroup,
    required this.medicalHistory,
    required this.allergies,
    required this.lastVisit,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'age': age,
    'gender': gender,
    'contact': contact,
    'bloodGroup': bloodGroup,
    'medicalHistory': medicalHistory,
    'allergies': allergies,
    'lastVisit': lastVisit,
    'ownerId': ownerId,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Patient.fromMap(Map<String, dynamic> map) => Patient(
    id: map['id'] as String,
    name: (map['name'] ?? '') as String,
    age: (map['age'] ?? '') as String,
    gender: (map['gender'] ?? '') as String,
    contact: (map['contact'] ?? '') as String,
    bloodGroup: (map['bloodGroup'] ?? '') as String,
    medicalHistory: (map['medicalHistory'] ?? '') as String,
    allergies: map['allergies'] == null
        ? const []
        : List<String>.from(map['allergies'] as List),
    lastVisit: (map['lastVisit'] ?? '') as String,
    ownerId: map['ownerId'] as String?,
    createdAt: map['createdAt'] == null
        ? null
        : DateTime.tryParse(map['createdAt'] as String),
    updatedAt: map['updatedAt'] == null
        ? null
        : DateTime.tryParse(map['updatedAt'] as String),
  );

  /// Row from `public.patients` -> UI model.
  /// DB types: age int?, last_visit_date date?, allergies text[].
  factory Patient.fromSupabase(Map<String, dynamic> row) {
    final rawDate = row['last_visit_date'] as String?;
    DateTime? parsedDate;
    if (rawDate != null && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }
    return Patient(
      id: row['id'] as String,
      ownerId: row['owner_id'] as String?,
      name: (row['name'] ?? '') as String,
      age: row['age'] == null ? '' : '${row['age']}',
      gender: (row['gender'] ?? '') as String,
      contact: (row['contact'] ?? '') as String,
      bloodGroup: (row['blood_group'] ?? '') as String,
      medicalHistory: (row['medical_history'] ?? '') as String,
      allergies: row['allergies'] == null
          ? const []
          : List<String>.from(row['allergies'] as List),
      lastVisit: parsedDate == null ? '' : formatDisplayDate(parsedDate),
      createdAt: row['created_at'] == null
          ? null
          : DateTime.tryParse(row['created_at'] as String),
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.tryParse(row['updated_at'] as String),
    );
  }

  /// UI model -> `public.patients` insert payload.
  /// `id` omitted so Postgres assigns `gen_random_uuid()`.
  /// `ownerId` must be the signed-in user's id (RLS enforces it too).
  Map<String, dynamic> toSupabase({required String ownerId}) {
    final parsedAge = int.tryParse(age.trim());
    final cleanAllergies = allergies.where((a) => a != 'None').toList();
    final today = DateTime.now();
    final todayIso =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    return {
      'owner_id': ownerId,
      'name': name.trim(),
      'age': parsedAge,
      'gender': gender.isEmpty ? null : gender,
      'contact': contact.trim().isEmpty ? null : contact.trim(),
      'blood_group': bloodGroup.isEmpty ? null : bloodGroup,
      'medical_history': medicalHistory,
      'allergies': cleanAllergies,
      'last_visit_date': todayIso,
    };
  }

  static String formatDisplayDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class PatientProvider extends ChangeNotifier {
  static const String _key = 'patients_list';

  List<Patient> _patients = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Patient> get patients => _patients;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  bool get useBackend => SupabaseConfig.isConfigured;
  String? get _userId => useBackend
      ? SupabaseConfig.client.auth.currentUser?.id
      : null;

  Future<void> loadPatients() async {
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
      _errorMessage = 'Could not load patients. Check connection and try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromSupabase() async {
    final userId = _userId;
    if (userId == null) {
      _patients = [];
      return;
    }
    final rows = await SupabaseConfig.client
        .from('patients')
        .select()
        .order('created_at', ascending: false);
    _patients = (rows as List)
        .map((r) => Patient.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  /// Local fallback when Supabase is not configured (fresh clone / offline).
  /// Starts empty — the old 30 demo seeds were dropped in Step 9.
  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];
    _patients = rawList
        .map((raw) => Patient.fromMap(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  Future<bool> addPatient(Patient patient) async {
    _errorMessage = '';
    if (useBackend) {
      final userId = _userId;
      if (userId == null) {
        _errorMessage = 'Please sign in again to add a patient.';
        notifyListeners();
        return false;
      }
      try {
        final row = await SupabaseConfig.client
            .from('patients')
            .insert(patient.toSupabase(ownerId: userId))
            .select()
            .single();
        _patients.insert(
          0,
          Patient.fromSupabase(row),
        );
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
    await _persistLocal();
    return true;
  }

  Future<bool> deletePatient(String id) async {
    _errorMessage = '';
    if (useBackend) {
      final userId = _userId;
      if (userId == null) {
        _errorMessage = 'Please sign in again.';
        notifyListeners();
        return false;
      }
      try {
        await SupabaseConfig.client.from('patients').delete().eq('id', id);
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
    await _persistLocal();
    return true;
  }

  /// Clears in-memory list (e.g. on logout so the next account
  /// never briefly sees the previous account's patients).
  void clearCache() {
    _patients = [];
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _patients.map((p) => jsonEncode(p.toMap())).toList();
    await prefs.setStringList(_key, rawList);
  }
}
