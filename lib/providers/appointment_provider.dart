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

  static List<Appointment> get _seedAppointments {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String formatDate(DateTime date) {
      const months = [
        'January', 'February', 'March', 'April',
        'May', 'June', 'July', 'August',
        'September', 'October', 'November', 'December',
      ];

      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }

    Appointment appointment({
      required int id,
      required String name,
      required String age,
      required int dayOffset,
      required String time,
      required String reason,
      required String doctor,
      required String status,
    }) {
      final date = today.add(Duration(days: dayOffset));

      return Appointment(
        id: 'seed-$id',
        patientId: 'seed-$id',
        patientName: name,
        date: formatDate(date),
        dateIso: date.toIso8601String().split('T').first,
        time: time,
        reason: reason,
        doctor: doctor,
        status: status,
      );
    }

    return [
      appointment(id: 1, name: 'John Doe', age: '28', dayOffset: 0, time: '09:00 AM', reason: 'General Checkup', doctor: 'Dr. Sarah Ahmed', status: 'scheduled'),
      appointment(id: 2, name: 'Emily Smith', age: '32', dayOffset: 0, time: '09:30 AM', reason: 'Follow-up Consultation', doctor: 'Dr. James Wilson', status: 'scheduled'),
      appointment(id: 3, name: 'Michael Brown', age: '45', dayOffset: 0, time: '10:00 AM', reason: 'Hypertension Review', doctor: 'Dr. Emily Clark', status: 'scheduled'),
      appointment(id: 4, name: 'Sarah Johnson', age: '29', dayOffset: 0, time: '10:30 AM', reason: 'Routine Checkup', doctor: 'Dr. Sarah Ahmed', status: 'scheduled'),
      appointment(id: 5, name: 'David Wilson', age: '50', dayOffset: 0, time: '11:00 AM', reason: 'Blood Pressure Check', doctor: 'Dr. James Wilson', status: 'scheduled'),
      appointment(id: 6, name: 'Olivia Davis', age: '26', dayOffset: 0, time: '11:30 AM', reason: 'Headache', doctor: 'Dr. Emily Clark', status: 'scheduled'),
      appointment(id: 7, name: 'James Miller', age: '38', dayOffset: 0, time: '12:00 PM', reason: 'Asthma Review', doctor: 'Dr. Sarah Ahmed', status: 'scheduled'),
      appointment(id: 8, name: 'Sophia Anderson', age: '31', dayOffset: 0, time: '01:00 PM', reason: 'Thyroid Follow-up', doctor: 'Dr. James Wilson', status: 'scheduled'),
      appointment(id: 9, name: 'Daniel Taylor', age: '42', dayOffset: 0, time: '01:30 PM', reason: 'Cholesterol Check', doctor: 'Dr. Emily Clark', status: 'scheduled'),
      appointment(id: 10, name: 'Isabella Thomas', age: '24', dayOffset: 0, time: '02:00 PM', reason: 'Routine Checkup', doctor: 'Dr. Sarah Ahmed', status: 'scheduled'),

      appointment(id: 11, name: 'Robert Moore', age: '55', dayOffset: 1, time: '09:00 AM', reason: 'Diabetes Follow-up', doctor: 'Dr. James Wilson', status: 'scheduled'),
      appointment(id: 12, name: 'Mia Jackson', age: '27', dayOffset: 2, time: '09:30 AM', reason: 'Fatigue Consultation', doctor: 'Dr. Emily Clark', status: 'scheduled'),
      appointment(id: 13, name: 'William Martin', age: '48', dayOffset: 3, time: '10:00 AM', reason: 'General Consultation', doctor: 'Dr. Sarah Ahmed', status: 'scheduled'),
      appointment(id: 14, name: 'Charlotte Lee', age: '35', dayOffset: 4, time: '10:30 AM', reason: 'Skin Consultation', doctor: 'Dr. James Wilson', status: 'scheduled'),
      appointment(id: 15, name: 'Benjamin Harris', age: '40', dayOffset: 5, time: '11:00 AM', reason: 'Back Pain', doctor: 'Dr. Emily Clark', status: 'scheduled'),
      appointment(id: 16, name: 'Amelia Clark', age: '33', dayOffset: 6, time: '11:30 AM', reason: 'Migraine Review', doctor: 'Dr. Sarah Ahmed', status: 'scheduled'),
      appointment(id: 17, name: 'Lucas Lewis', age: '52', dayOffset: 7, time: '12:00 PM', reason: 'Cardiology Follow-up', doctor: 'Dr. James Wilson', status: 'scheduled'),
      appointment(id: 18, name: 'Harper Walker', age: '30', dayOffset: 8, time: '01:00 PM', reason: 'Allergy Consultation', doctor: 'Dr. Emily Clark', status: 'scheduled'),
      appointment(id: 19, name: 'Henry Hall', age: '60', dayOffset: 9, time: '01:30 PM', reason: 'Joint Pain', doctor: 'Dr. Sarah Ahmed', status: 'scheduled'),
      appointment(id: 20, name: 'Evelyn Allen', age: '41', dayOffset: 10, time: '02:00 PM', reason: 'Blood Pressure Follow-up', doctor: 'Dr. James Wilson', status: 'scheduled'),

      appointment(id: 21, name: 'Alexander Young', age: '36', dayOffset: -1, time: '09:00 AM', reason: 'General Checkup', doctor: 'Dr. Emily Clark', status: 'completed'),
      appointment(id: 22, name: 'Abigail King', age: '28', dayOffset: -2, time: '09:30 AM', reason: 'Breathing Difficulty', doctor: 'Dr. Sarah Ahmed', status: 'completed'),
      appointment(id: 23, name: 'Matthew Wright', age: '47', dayOffset: -3, time: '10:00 AM', reason: 'Diabetes Review', doctor: 'Dr. James Wilson', status: 'completed'),
      appointment(id: 24, name: 'Ella Scott', age: '34', dayOffset: -4, time: '10:30 AM', reason: 'Routine Consultation', doctor: 'Dr. Emily Clark', status: 'completed'),
      appointment(id: 25, name: 'Joseph Green', age: '57', dayOffset: -5, time: '11:00 AM', reason: 'Hypertension Review', doctor: 'Dr. Sarah Ahmed', status: 'completed'),
      appointment(id: 26, name: 'Grace Baker', age: '39', dayOffset: -6, time: '11:30 AM', reason: 'Thyroid Consultation', doctor: 'Dr. James Wilson', status: 'completed'),
      appointment(id: 27, name: 'Samuel Adams', age: '44', dayOffset: -7, time: '12:00 PM', reason: 'Health Checkup', doctor: 'Dr. Emily Clark', status: 'completed'),
      appointment(id: 28, name: 'Chloe Nelson', age: '23', dayOffset: -8, time: '01:00 PM', reason: 'Migraine Consultation', doctor: 'Dr. Sarah Ahmed', status: 'completed'),
      appointment(id: 29, name: 'Christopher Carter', age: '51', dayOffset: -9, time: '01:30 PM', reason: 'Arthritis Follow-up', doctor: 'Dr. James Wilson', status: 'completed'),
      appointment(id: 30, name: 'Lily Mitchell', age: '37', dayOffset: -10, time: '02:00 PM', reason: 'Annual Checkup', doctor: 'Dr. Emily Clark', status: 'completed'),
    ];
  }

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