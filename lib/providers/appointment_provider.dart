import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';

class Appointment {
  final String id; // uuid from Supabase, or local millis key in fallback mode
  final String? patientId;
  final String patientName;
  final String date;
  final String dateIso;
  final String time;
  final String reason;
  final String doctor;
  final String status;

  // Step 10/12: backend identity + timestamps (null in local fallback mode).
  final String? ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.ownerId,
    this.createdAt,
    this.updatedAt,
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
    'ownerId': ownerId,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Appointment.fromMap(Map<String, dynamic> map) => Appointment(
    id: map['id'] as String,
    patientId: map['patientId'] as String?,
    patientName: (map['patientName'] ?? '') as String,
    date: (map['date'] ?? '') as String,
    dateIso: (map['dateIso'] ?? '') as String,
    time: (map['time'] ?? '') as String,
    reason: (map['reason'] ?? '') as String,
    doctor: (map['doctor'] ?? '') as String,
    status: (map['status'] ?? 'scheduled') as String,
    ownerId: map['ownerId'] as String?,
    createdAt: map['createdAt'] == null
        ? null
        : DateTime.tryParse(map['createdAt'] as String),
    updatedAt: map['updatedAt'] == null
        ? null
        : DateTime.tryParse(map['updatedAt'] as String),
  );

  /// Row from `public.appointments` -> UI model.
  factory Appointment.fromSupabase(Map<String, dynamic> row) {
    final iso = (row['date_iso'] ?? '') as String;
    var label = (row['date_label'] ?? '') as String;
    if (label.isEmpty && iso.isNotEmpty) {
      final parsed = DateTime.tryParse(iso);
      if (parsed != null) label = formatDisplayDate(parsed);
    }
    return Appointment(
      id: row['id'] as String,
      ownerId: row['owner_id'] as String?,
      patientId: row['patient_id'] as String?,
      patientName: (row['patient_name'] ?? '') as String,
      date: label,
      dateIso: iso,
      time: (row['time_text'] ?? '') as String,
      reason: (row['reason'] ?? '') as String,
      doctor: (row['doctor_name'] ?? '') as String,
      status: (row['status'] ?? 'scheduled') as String,
      createdAt: row['created_at'] == null
          ? null
          : DateTime.tryParse(row['created_at'] as String),
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.tryParse(row['updated_at'] as String),
    );
  }

  /// UI model -> `public.appointments` insert payload.
  /// `id` omitted so Postgres assigns `gen_random_uuid()`.
  /// `patient_id` sent only when it is a real uuid (FK to patients);
  /// legacy local ids are dropped to null, `patient_name` is kept.
  Map<String, dynamic> toSupabase({required String ownerId}) {
    var iso = dateIso.trim();
    if (iso.isEmpty) {
      final now = DateTime.now();
      iso = '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
    }
    var label = date.trim();
    if (label.isEmpty) {
      final parsed = DateTime.tryParse(iso);
      if (parsed != null) label = formatDisplayDate(parsed);
    }
    return {
      'owner_id': ownerId,
      'patient_id': isUuid(patientId) ? patientId : null,
      'patient_name': patientName.trim(),
      'date_iso': iso,
      'date_label': label,
      'time_text': time,
      'reason': reason,
      'doctor_name': doctor,
      'status': status.isEmpty ? 'scheduled' : status,
    };
  }

  static bool isUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  static String formatDisplayDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

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
    ownerId: ownerId,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

class AppointmentProvider extends ChangeNotifier {
  static const String _key = 'appointments_list';

  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  bool get useBackend => SupabaseConfig.isConfigured;
  String? get _userId => useBackend
      ? SupabaseConfig.client.auth.currentUser?.id
      : null;

  Future<void> loadAppointments() async {
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
          'Could not load appointments. Check connection and try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromSupabase() async {
    final userId = _userId;
    if (userId == null) {
      _appointments = [];
      return;
    }
    final rows = await SupabaseConfig.client
        .from('appointments')
        .select()
        .order('date_iso', ascending: true);
    _appointments = (rows as List)
        .map((r) => Appointment.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  /// Local fallback when Supabase is not configured (fresh clone / offline).
  /// Starts empty — the old demo seeds were dropped in Step 10.
  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];
    _appointments = rawList
        .map((raw) => Appointment.fromMap(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  List<Appointment> visitHistoryForPatient(String patientId) {
    final visits = _appointments
        .where((a) => a.patientId == patientId && a.status == 'completed')
        .toList();
    visits.sort((a, b) => b.dateIso.compareTo(a.dateIso));
    return visits;
  }

  Future<bool> addAppointment(Appointment appointment) async {
    _errorMessage = '';
    if (useBackend) {
      final userId = _userId;
      if (userId == null) {
        _errorMessage = 'Please sign in again to add an appointment.';
        notifyListeners();
        return false;
      }
      try {
        final row = await SupabaseConfig.client
            .from('appointments')
            .insert(appointment.toSupabase(ownerId: userId))
            .select()
            .single();
        _appointments.insert(0, Appointment.fromSupabase(row));
        notifyListeners();
        return true;
      } catch (_) {
        _errorMessage =
            'Could not save appointment. Check connection and try again.';
        notifyListeners();
        return false;
      }
    }

    _appointments.insert(
      0,
      appointment.id.isEmpty
          ? Appointment(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              patientId: appointment.patientId,
              patientName: appointment.patientName,
              date: appointment.date,
              dateIso: appointment.dateIso,
              time: appointment.time,
              reason: appointment.reason,
              doctor: appointment.doctor,
              status: appointment.status,
            )
          : appointment,
    );
    notifyListeners();
    await _persistLocal();
    return true;
  }

  Future<bool> updateStatus(String id, String newStatus) async {
    _errorMessage = '';
    if (useBackend) {
      final userId = _userId;
      if (userId == null) {
        _errorMessage = 'Please sign in again.';
        notifyListeners();
        return false;
      }
      try {
        await SupabaseConfig.client
            .from('appointments')
            .update({'status': newStatus})
            .eq('id', id);
        final index = _appointments.indexWhere((a) => a.id == id);
        if (index != -1) {
          _appointments[index] = _appointments[index].copyWith(
            status: newStatus,
          );
          notifyListeners();
        }
        return true;
      } catch (_) {
        _errorMessage = 'Could not update appointment. Try again.';
        notifyListeners();
        return false;
      }
    }

    final index = _appointments.indexWhere((a) => a.id == id);
    if (index == -1) return false;
    _appointments[index] = _appointments[index].copyWith(status: newStatus);
    notifyListeners();
    await _persistLocal();
    return true;
  }

  /// Clears in-memory list (e.g. on logout so the next account
  /// never briefly sees the previous account's appointments).
  void clearCache() {
    _appointments = [];
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _appointments.map((a) => jsonEncode(a.toMap())).toList();
    await prefs.setStringList(_key, rawList);
  }
}
