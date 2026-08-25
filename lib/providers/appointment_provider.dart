import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Appointment {
  final String id;
  final String? patientId;
  final String patientName;
  final String date;
  final String dateIso;
  final String time;
  final String reason;
  final String doctor;
  final String status;

  Appointment({
    required this.id,
    this.patientId,
    required this.patientName,
    required this.date,
    required this.dateIso,
    required this.time,
    required this.reason,
    required this.doctor,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'patientId': patientId,
    'patientName': patientName,
    'date': date,
    'dateIso': dateIso,
    'time': time,
    'reason': reason,
    'doctor': doctor,
    'status': status,
  };

  factory Appointment.fromMap(Map<String, dynamic> map) => Appointment(
    id: map['id'] as String,
    patientId: map['patientId'] as String?,
    patientName: map['patientName'] as String,
    date: map['date'] as String,
    dateIso: map['dateIso'] as String? ?? '',
    time: map['time'] as String,
    reason: map['reason'] as String,
    doctor: map['doctor'] as String,
    status: map['status'] as String,
  );

  Appointment copyWith({String? status}) => Appointment(
    id: id,
    patientId: patientId,
    patientName: patientName,
    date: date,
    dateIso: dateIso,
    time: time,
    reason: reason,
    doctor: doctor,
    status: status ?? this.status,
  );
}

class AppointmentProvider extends ChangeNotifier {
  static const String _key = 'appointments_list';

  List<Appointment> _appointments = [];

  List<Appointment> get appointments => _appointments;

  static final List<Appointment> _seedAppointments = [
    Appointment(id: 'seed-1', patientId: 'seed-1', patientName: 'John Doe', date: '18 May 2025', dateIso: '2025-05-18', time: '09:00 AM', reason: 'General Checkup', doctor: 'Dr. Sarah Ahmed', status: 'scheduled'),
    Appointment(id: 'seed-2', patientId: 'seed-2', patientName: 'Emily Smith', date: '17 May 2025', dateIso: '2025-05-17', time: '10:30 AM', reason: 'Fever & Cold', doctor: 'Dr. Sarah Ahmed', status: 'scheduled'),
    Appointment(id: 'seed-3', patientId: 'seed-3', patientName: 'Michael Brown', date: '15 May 2025', dateIso: '2025-05-15', time: '12:00 PM', reason: 'Follow-up', doctor: 'Dr. James Wilson', status: 'completed'),
    Appointment(id: 'seed-4', patientId: 'seed-4', patientName: 'Sarah Johnson', date: '14 May 2025', dateIso: '2025-05-14', time: '02:30 PM', reason: 'Consultation', doctor: 'Dr. Emily Clark', status: 'completed'),
  ];

  Future<void> loadAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key);

    if (rawList == null) {
      _appointments = List.from(_seedAppointments);
      await _persist();
    } else {
      _appointments = rawList
          .map((raw) => Appointment.fromMap(jsonDecode(raw) as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  List<Appointment> visitHistoryForPatient(String patientId) {
    final visits = _appointments
        .where((a) => a.patientId == patientId && a.status == 'completed')
        .toList();
    visits.sort((a, b) => b.dateIso.compareTo(a.dateIso));
    return visits;
  }

  Future<void> addAppointment(Appointment appointment) async {
    _appointments.insert(0, appointment);
    notifyListeners();
    await _persist();
  }

  Future<void> updateStatus(String id, String newStatus) async {
    final index = _appointments.indexWhere((a) => a.id == id);
    if (index == -1) return;
    _appointments[index] = _appointments[index].copyWith(status: newStatus);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _appointments.map((a) => jsonEncode(a.toMap())).toList();
    await prefs.setStringList(_key, rawList);
  }
}