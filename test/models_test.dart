import 'package:clinitrack/models/appointment.dart';
import 'package:clinitrack/models/follow_up.dart';
import 'package:clinitrack/models/medicine.dart';
import 'package:clinitrack/models/patient.dart';
import 'package:clinitrack/models/prescription.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Patient model', () {
    test('toSupabase parses age, drops None allergy, nulls empties', () {
      final p = Patient(
        id: '1',
        name: '  Rahim Uddin  ',
        age: '34',
        gender: '',
        contact: '',
        bloodGroup: '',
        medicalHistory: 'Diabetes',
        allergies: ['Penicillin', 'None', 'Dust'],
        lastVisit: '',
      );
      final map = p.toSupabase(ownerId: 'owner-1');
      expect(map['name'], 'Rahim Uddin');
      expect(map['age'], 34);
      expect(map['allergies'], ['Penicillin', 'Dust']);
      expect(map['gender'], isNull);
      expect(map['last_visit_date'], matches(RegExp(r'\d{4}-\d{2}-\d{2}')));
    });

    test('toSupabase handles non-numeric age as null', () {
      final p = Patient(
        id: '1',
        name: 'A',
        age: 'unknown',
        gender: 'Male',
        contact: '01x',
        bloodGroup: 'B+',
        medicalHistory: '',
        allergies: const [],
        lastVisit: '',
      );
      expect(p.toSupabase(ownerId: 'o')['age'], isNull);
    });

    test('fromSupabase maps db types to UI strings', () {
      final p = Patient.fromSupabase({
        'id': 'uuid-1',
        'owner_id': 'owner-1',
        'name': 'Sara',
        'age': 29,
        'gender': 'Female',
        'contact': '019',
        'blood_group': 'O+',
        'medical_history': 'None',
        'allergies': ['Dust'],
        'last_visit_date': '2026-05-01',
        'created_at': null,
        'updated_at': null,
      });
      expect(p.age, '29');
      expect(p.bloodGroup, 'O+');
      expect(p.lastVisit, isNotEmpty);
    });

    test('fromMap round-trips local cache', () {
      final p = Patient(
        id: '7',
        name: 'N',
        age: '5',
        gender: 'Other',
        contact: 'c',
        bloodGroup: 'A+',
        medicalHistory: 'h',
        allergies: const ['X'],
        lastVisit: 'v',
      );
      final back = Patient.fromMap(p.toMap());
      expect(back.name, 'N');
      expect(back.allergies, ['X']);
    });
  });

  group('Appointment model', () {
    test('isUuid accepts only real uuids', () {
      expect(Appointment.isUuid('123e4567-e89b-12d3-a456-426614174000'),
          isTrue);
      expect(Appointment.isUuid('123'), isFalse);
      expect(Appointment.isUuid(null), isFalse);
      expect(Appointment.isUuid(''), isFalse);
    });

    test('toSupabase defaults status and fills iso/label', () {
      final a = Appointment(
        id: '',
        patientName: ' Karim ',
        date: '',
        dateIso: '',
        time: '10:00 AM',
        reason: 'Fever',
        doctor: 'Dr. X',
        status: '',
      );
      final map = a.toSupabase(ownerId: 'owner-1');
      expect(map['status'], 'scheduled');
      expect((map['date_iso'] as String).isNotEmpty, isTrue);
      expect(map['patient_name'], 'Karim');
      // Legacy local patient ids must be dropped for FK safety.
      expect(map['patient_id'], isNull);
    });

    test('fromSupabase derives label when missing', () {
      final a = Appointment.fromSupabase({
        'id': 'a1',
        'owner_id': 'o',
        'patient_id': null,
        'patient_name': 'P',
        'date_iso': '2026-06-15',
        'date_label': '',
        'time_text': '9:00 AM',
        'reason': 'Checkup',
        'doctor_name': 'Dr. Y',
        'status': 'requested',
        'created_at': null,
        'updated_at': null,
      });
      expect(a.dateIso, '2026-06-15');
      expect(a.date, contains('2026'));
      expect(a.status, 'requested');
    });
  });

  group('Prescription model', () {
    test('summary format and frequency default', () {
      final p = Prescription(
        id: '',
        patientId: 'local-123',
        medicineName: 'Paracetamol',
        dosage: '500mg',
        duration: '5 days',
        frequency: '',
        notes: '',
      );
      expect(p.summary, contains('Paracetamol'));
      expect(p.toSupabase(ownerId: 'o')['frequency'], 'Daily');
      // Local ids are not sent as uuid FK.
      expect(p.toSupabase(ownerId: 'o')['patient_id'], isNull);
    });

    test('fromSupabase maps duration_text column', () {
      final p = Prescription.fromSupabase({
        'id': 'rx1',
        'owner_id': 'o',
        'patient_id': 'pid',
        'medicine_name': 'Amoxicillin',
        'dosage': '250mg',
        'duration_text': '7 days',
        'frequency': 'Twice a day',
        'notes': 'After meal',
        'created_at': null,
      });
      expect(p.duration, '7 days');
      expect(p.summary, contains('Twice a day'));
    });
  });

  group('FollowUp model', () {
    test('formatDisplayDate + copyWith toggle', () {
      expect(FollowUp.formatDisplayDate(DateTime(2026, 5, 9)), '9 May 2026');
      final f = FollowUp(
        id: '1',
        patientName: 'P',
        dateIso: '2026-05-09',
        dateLabel: '9 May 2026',
        time: '10:00 AM',
        notes: '',
      );
      expect(f.copyWith(isDone: true).isDone, isTrue);
    });

    test('toSupabase fills missing iso with today', () {
      final f = FollowUp(
        id: '',
        patientName: 'P',
        dateIso: '',
        dateLabel: '',
        time: '',
        notes: '',
      );
      final map = f.toSupabase(ownerId: 'o');
      expect((map['follow_up_date'] as String).length, 10);
    });
  });

  group('Medicine model', () {
    test('toSupabase defaults category/unit and clamps stock', () {
      final m = Medicine(
          id: '', name: ' Napa ', category: '', stock: -3, unit: '');
      final map = m.toSupabase(ownerId: 'o');
      expect(map['name'], 'Napa');
      expect(map['category'], 'General');
      expect(map['unit'], 'tablets');
      expect(map['stock'], 0);
    });

    test('copyWith updates stock only', () {
      final m =
          Medicine(id: '1', name: 'X', category: 'G', stock: 10, unit: 'pcs');
      expect(m.copyWith(stock: 3).stock, 3);
      expect(m.copyWith(stock: 3).name, 'X');
    });
  });
}
