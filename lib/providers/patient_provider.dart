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
    Patient(id: 'seed-1', name: 'John Doe', age: '28', gender: 'Male', contact: '01710000001', bloodGroup: 'O+', medicalHistory: 'No major illnesses.', allergies: const ['Penicillin'], lastVisit: '20 August 2026'),
    Patient(id: 'seed-2', name: 'Emily Smith', age: '32', gender: 'Female', contact: '01710000002', bloodGroup: 'A+', medicalHistory: 'Seasonal allergies.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-3', name: 'Michael Brown', age: '45', gender: 'Male', contact: '01710000003', bloodGroup: 'B+', medicalHistory: 'Hypertension.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-4', name: 'Sarah Johnson', age: '29', gender: 'Female', contact: '01710000004', bloodGroup: 'AB+', medicalHistory: 'No major illnesses.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-5', name: 'David Wilson', age: '50', gender: 'Male', contact: '01710000005', bloodGroup: 'O-', medicalHistory: 'Type 2 diabetes.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-6', name: 'Olivia Davis', age: '26', gender: 'Female', contact: '01710000006', bloodGroup: 'A-', medicalHistory: 'Migraine.', allergies: const ['Dust'], lastVisit: '20 August 2026'),
    Patient(id: 'seed-7', name: 'James Miller', age: '38', gender: 'Male', contact: '01710000007', bloodGroup: 'B+', medicalHistory: 'Asthma.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-8', name: 'Sophia Anderson', age: '31', gender: 'Female', contact: '01710000008', bloodGroup: 'O+', medicalHistory: 'Thyroid condition.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-9', name: 'Daniel Taylor', age: '42', gender: 'Male', contact: '01710000009', bloodGroup: 'AB-', medicalHistory: 'High cholesterol.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-10', name: 'Isabella Thomas', age: '24', gender: 'Female', contact: '01710000010', bloodGroup: 'A+', medicalHistory: 'No significant history.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-11', name: 'Robert Moore', age: '55', gender: 'Male', contact: '01710000011', bloodGroup: 'O+', medicalHistory: 'Hypertension.', allergies: const ['Aspirin'], lastVisit: '20 August 2026'),
    Patient(id: 'seed-12', name: 'Mia Jackson', age: '27', gender: 'Female', contact: '01710000012', bloodGroup: 'B-', medicalHistory: 'Anemia.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-13', name: 'William Martin', age: '48', gender: 'Male', contact: '01710000013', bloodGroup: 'A-', medicalHistory: 'Diabetes.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-14', name: 'Charlotte Lee', age: '35', gender: 'Female', contact: '01710000014', bloodGroup: 'O-', medicalHistory: 'No major illnesses.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-15', name: 'Benjamin Harris', age: '40', gender: 'Male', contact: '01710000015', bloodGroup: 'B+', medicalHistory: 'Back pain.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-16', name: 'Amelia Clark', age: '33', gender: 'Female', contact: '01710000016', bloodGroup: 'AB+', medicalHistory: 'Migraine.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-17', name: 'Lucas Lewis', age: '52', gender: 'Male', contact: '01710000017', bloodGroup: 'O+', medicalHistory: 'Heart disease.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-18', name: 'Harper Walker', age: '30', gender: 'Female', contact: '01710000018', bloodGroup: 'A+', medicalHistory: 'Seasonal allergies.', allergies: const ['Pollen'], lastVisit: '20 August 2026'),
    Patient(id: 'seed-19', name: 'Henry Hall', age: '60', gender: 'Male', contact: '01710000019', bloodGroup: 'B-', medicalHistory: 'Arthritis.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-20', name: 'Evelyn Allen', age: '41', gender: 'Female', contact: '01710000020', bloodGroup: 'O-', medicalHistory: 'Hypertension.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-21', name: 'Alexander Young', age: '36', gender: 'Male', contact: '01710000021', bloodGroup: 'AB+', medicalHistory: 'No major illnesses.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-22', name: 'Abigail King', age: '28', gender: 'Female', contact: '01710000022', bloodGroup: 'A-', medicalHistory: 'Asthma.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-23', name: 'Matthew Wright', age: '47', gender: 'Male', contact: '01710000023', bloodGroup: 'O+', medicalHistory: 'Diabetes.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-24', name: 'Ella Scott', age: '34', gender: 'Female', contact: '01710000024', bloodGroup: 'B+', medicalHistory: 'No significant history.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-25', name: 'Joseph Green', age: '57', gender: 'Male', contact: '01710000025', bloodGroup: 'AB-', medicalHistory: 'Hypertension.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-26', name: 'Grace Baker', age: '39', gender: 'Female', contact: '01710000026', bloodGroup: 'O+', medicalHistory: 'Thyroid condition.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-27', name: 'Samuel Adams', age: '44', gender: 'Male', contact: '01710000027', bloodGroup: 'A+', medicalHistory: 'High cholesterol.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-28', name: 'Chloe Nelson', age: '23', gender: 'Female', contact: '01710000028', bloodGroup: 'B-', medicalHistory: 'Migraine.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-29', name: 'Christopher Carter', age: '51', gender: 'Male', contact: '01710000029', bloodGroup: 'O-', medicalHistory: 'Arthritis.', allergies: const [], lastVisit: '20 August 2026'),
    Patient(id: 'seed-30', name: 'Lily Mitchell', age: '37', gender: 'Female', contact: '01710000030', bloodGroup: 'AB+', medicalHistory: 'No major illnesses.', allergies: const [], lastVisit: '20 August 2026'),
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