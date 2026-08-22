import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Patient {
  final String id;
  final String name;
  final String age;
  final String gender;
  final String contact;
  final String bloodGroup;
  final String medicalHistory;
  final List<String> allergies;
  final String lastVisit;

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
  };

  factory Patient.fromMap(Map<String, dynamic> map) => Patient(
    id: map['id'] as String,
    name: map['name'] as String,
    age: map['age'] as String,
    gender: map['gender'] as String,
    contact: map['contact'] as String,
    bloodGroup: map['bloodGroup'] as String,
    medicalHistory: map['medicalHistory'] as String,
    allergies: List<String>.from(map['allergies'] as List),
    lastVisit: map['lastVisit'] as String,
  );
}

class PatientProvider extends ChangeNotifier {
  static const String _key = 'patients_list';

  List<Patient> _patients = [];

  List<Patient> get patients => _patients;
  static final List<Patient> _seedPatients = [
    Patient(id: 'seed-1', name: 'John Doe', age: '28', gender: 'Male', contact: '01912345678', bloodGroup: 'O+', medicalHistory: 'No major illnesses in the past.', allergies: const ['Penicillin'], lastVisit: '18 May 2025'),
    Patient(id: 'seed-2', name: 'Emily Smith', age: '32', gender: 'Female', contact: '01912345679', bloodGroup: 'A+', medicalHistory: 'Seasonal allergies.', allergies: const [], lastVisit: '17 May 2025'),
    Patient(id: 'seed-3', name: 'Michael Brown', age: '45', gender: 'Male', contact: '01912345680', bloodGroup: 'B+', medicalHistory: 'Hypertension, managed.', allergies: const [], lastVisit: '15 May 2025'),
    Patient(id: 'seed-4', name: 'Sarah Johnson', age: '29', gender: 'Female', contact: '01912345681', bloodGroup: 'AB+', medicalHistory: 'No major illnesses in the past.', allergies: const [], lastVisit: '14 May 2025'),
    Patient(id: 'seed-5', name: 'David Wilson', age: '50', gender: 'Male', contact: '01912345682', bloodGroup: 'O-', medicalHistory: 'Type 2 diabetes.', allergies: const [], lastVisit: '10 May 2025'),
  ];

  Future<void> loadPatients() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key);

    if (rawList == null) {
      _patients = List.from(_seedPatients);
      await _persist();
    } else {
      _patients = rawList
          .map((raw) => Patient.fromMap(jsonDecode(raw) as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  Future<void> addPatient(Patient patient) async {
    _patients.insert(0, patient);
    notifyListeners();
    await _persist();
  }

  Future<void> deletePatient(String id) async {
    _patients.removeWhere((p) => p.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _patients.map((p) => jsonEncode(p.toMap())).toList();
    await prefs.setStringList(_key, rawList);
  }
}