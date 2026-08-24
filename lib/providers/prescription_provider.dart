import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prescription {
  final String id;
  final String patientId;
  final String medicineName;
  final String dosage;
  final String duration;
  final String frequency;
  final String notes;

  Prescription({
    required this.id,
    required this.patientId,
    required this.medicineName,
    required this.dosage,
    required this.duration,
    required this.frequency,
    required this.notes,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'patientId': patientId,
    'medicineName': medicineName,
    'dosage': dosage,
    'duration': duration,
    'frequency': frequency,
    'notes': notes,
  };

  factory Prescription.fromMap(Map<String, dynamic> map) => Prescription(
    id: map['id'] as String,
    patientId: map['patientId'] as String,
    medicineName: map['medicineName'] as String,
    dosage: map['dosage'] as String,
    duration: map['duration'] as String,
    frequency: map['frequency'] as String,
    notes: map['notes'] as String,
  );

  String get summary => '$medicineName $dosage — $frequency, $duration';
}

class PrescriptionProvider extends ChangeNotifier {
  static const String _key = 'prescriptions_list';

  List<Prescription> _prescriptions = [];

  List<Prescription> get prescriptions => _prescriptions;

  List<Prescription> forPatient(String patientId) =>
      _prescriptions.where((p) => p.patientId == patientId).toList();

  Future<void> loadPrescriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];
    _prescriptions = rawList
        .map((raw) => Prescription.fromMap(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> addPrescription(Prescription prescription) async {
    _prescriptions.insert(0, prescription);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _prescriptions.map((p) => jsonEncode(p.toMap())).toList();
    await prefs.setStringList(_key, rawList);
  }
}