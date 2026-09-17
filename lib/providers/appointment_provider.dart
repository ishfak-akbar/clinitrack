import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../repositories/appointment_repository.dart';

export '../models/appointment.dart';

/// Step 14: UI state only — all data access goes through [AppointmentRepository].
class AppointmentProvider extends ChangeNotifier {
  final AppointmentRepository _repo = AppointmentRepository();

  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  bool get useBackend => _repo.useBackend;

  Future<void> loadAppointments() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (useBackend) {
        if (_repo.userId == null) {
          _appointments = [];
        } else {
          _appointments = await _repo.fetchAll();
        }
      } else {
        _appointments = await _repo.loadLocal();
      }
    } catch (_) {
      _errorMessage =
          'Could not load appointments. Check connection and try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  List<Appointment> visitHistoryForPatient(String patientId) {
    final visits = _appointments
        .where((a) => a.patientId == patientId && a.status == 'completed')
        .toList();
    visits.sort((a, b) => b.dateIso.compareTo(a.dateIso));
    return visits;
  }

  /// Part 5: patient bookings pass the chosen doctor's id as [ownerId].
  /// Defaults to the signed-in user (doctor flow).
  Future<bool> addAppointment(Appointment appointment,
      {String? ownerId}) async {
    _errorMessage = '';
    if (useBackend) {
      final userId = _repo.userId;
      if (userId == null) {
        _errorMessage = 'Please sign in again to add an appointment.';
        notifyListeners();
        return false;
      }
      try {
        final saved = await _repo.insert(appointment, ownerId ?? userId);
        _appointments.insert(0, saved);
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
    await _repo.saveLocal(_appointments);
    return true;
  }

  Future<bool> updateStatus(String id, String newStatus) async {
    _errorMessage = '';
    if (useBackend) {
      if (_repo.userId == null) {
        _errorMessage = 'Please sign in again.';
        notifyListeners();
        return false;
      }
      try {
        await _repo.updateStatus(id, newStatus);
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
    await _repo.saveLocal(_appointments);
    return true;
  }

  /// Clears in-memory list (e.g. on logout so the next account
  /// never briefly sees the previous account's appointments).
  void clearCache() {
    _appointments = [];
    _errorMessage = '';
    notifyListeners();
  }
}
