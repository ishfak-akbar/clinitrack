import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/follow_up.dart';
import '../models/medicine.dart';
import '../models/patient.dart';
import '../models/prescription.dart';
import '../services/stats_service.dart';

/// Step 13: Reports/Dashboard numbers.
///
/// Backend mode: every number comes from server-side `COUNT(*)` queries
/// ([StatsService.fetchStats]). Offline/fallback mode: computed from the
/// already-loaded provider lists.
class StatsProvider extends ChangeNotifier {
  ClinicStats _stats = const ClinicStats();
  bool _isLoading = false;
  String _errorMessage = '';

  ClinicStats get stats => _stats;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  bool get useBackend => StatsService.useBackend;

  Future<void> refresh({
    List<Patient> patients = const [],
    List<Appointment> appointments = const [],
    List<Prescription> prescriptions = const [],
    List<FollowUp> followUps = const [],
    List<Medicine> medicines = const [],
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (useBackend) {
        _stats = await StatsService.fetchStats();
      } else {
        _stats = _fromLocal(
          patients: patients,
          appointments: appointments,
          prescriptions: prescriptions,
          followUps: followUps,
          medicines: medicines,
        );
      }
    } catch (_) {
      _errorMessage =
          'Could not load stats. Check connection and try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  ClinicStats _fromLocal({
    required List<Patient> patients,
    required List<Appointment> appointments,
    required List<Prescription> prescriptions,
    required List<FollowUp> followUps,
    required List<Medicine> medicines,
  }) {
    return StatsService.computeLocal(
      patients: patients,
      appointments: appointments,
      prescriptions: prescriptions,
      followUps: followUps,
      medicines: medicines,
    );
  }

  void clearCache() {
    _stats = const ClinicStats();
    _errorMessage = '';
    notifyListeners();
  }
}
