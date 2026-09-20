import 'package:clinitrack/models/appointment.dart';
import 'package:clinitrack/models/follow_up.dart';
import 'package:clinitrack/models/medicine.dart';
import 'package:clinitrack/models/patient.dart';
import 'package:clinitrack/models/prescription.dart';
import 'package:clinitrack/providers/stats_provider.dart';
import 'package:clinitrack/services/stats_service.dart';
import 'package:flutter_test/flutter_test.dart';

Patient _patient(String id, {String gender = '', String blood = ''}) =>
    Patient(
      id: id,
      name: 'P $id',
      age: '30',
      gender: gender,
      contact: '',
      bloodGroup: blood,
      medicalHistory: '',
      allergies: const [],
      lastVisit: '',
    );

Appointment _appt(String id, String iso, {String status = 'scheduled'}) =>
    Appointment(
      id: id,
      patientName: 'P',
      date: iso,
      dateIso: iso,
      time: '10:00 AM',
      reason: 'Checkup',
      doctor: 'Dr. X',
      status: status,
    );

void main() {
  group('StatsService helpers', () {
    test('todayIso is yyyy-MM-dd', () {
      expect(StatsService.todayIso(), matches(RegExp(r'\d{4}-\d{2}-\d{2}')));
    });

    test('low stock threshold is 40 and blood groups complete', () {
      expect(StatsService.lowStockThreshold, 40);
      expect(StatsService.bloodGroups,
          containsAll(['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']));
    });
  });

  // NOTE: computeLocal is the pure offline path extracted from
  // StatsProvider. Provider.refresh() itself needs dotenv + backend and is
  // covered by integration, not unit tests.
  group('StatsService.computeLocal (offline mode)', () {
    test('counts totals, today, gender, blood, low stock, due', () {
      final today = StatsService.todayIso();

      final stats = StatsService.computeLocal(
        patients: [
          _patient('1', gender: 'Male', blood: 'A+'),
          _patient('2', gender: 'Female', blood: 'O+'),
          _patient('3', gender: 'Female', blood: 'O+'),
          _patient('4', gender: 'Unknown', blood: 'X'),
        ],
        appointments: [
          _appt('a1', today),
          _appt('a2', today, status: 'requested'),
          _appt('a3', '2000-01-01', status: 'completed'),
        ],
        prescriptions: [
          Prescription(
              id: 'r1',
              patientId: '1',
              medicineName: 'Napa',
              dosage: '500mg',
              duration: '5d',
              frequency: 'Daily',
              notes: ''),
        ],
        followUps: [
          FollowUp(
              id: 'f1',
              patientName: 'P',
              dateIso: today,
              dateLabel: today,
              time: '',
              notes: ''),
          FollowUp(
              id: 'f2',
              patientName: 'P',
              dateIso: today,
              dateLabel: today,
              time: '',
              notes: '',
              isDone: true),
        ],
        medicines: [
          Medicine(id: 'm1', name: 'A', category: 'G', stock: 5, unit: 'pcs'),
          Medicine(
              id: 'm2', name: 'B', category: 'G', stock: 100, unit: 'pcs'),
        ],
      );

      expect(stats.totalPatients, 4);
      expect(stats.totalAppointments, 3);
      expect(stats.todayAppointments, 2);
      expect(stats.totalPrescriptions, 1);
      // Only not-done counts as due.
      expect(stats.followUpsDue, 1);
      // Only stock < 40 counts.
      expect(stats.lowStockMedicines, 1);
      expect(stats.genderCounts['Male'], 1);
      expect(stats.genderCounts['Female'], 2);
      expect(stats.genderCounts['Other'], 0);
      expect(stats.totalByGender, 3);
      expect(stats.bloodGroupCounts['O+'], 2);
      expect(stats.bloodGroupCounts['A+'], 1);
    });

    test('empty lists give zero stats, not crash', () {
      final stats = StatsService.computeLocal();
      expect(stats.totalPatients, 0);
      expect(stats.todayAppointments, 0);
      expect(stats.followUpsDue, 0);
    });
  });

  group('StatsProvider (backend-free parts)', () {
    test('clearCache resets to zeros', () {
      final provider = StatsProvider();
      provider.clearCache();
      expect(provider.stats.totalPatients, 0);
      expect(provider.errorMessage, isEmpty);
    });
  });
}
