import 'package:clinitrack/models/appointment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Booking business rules shared by doctor + patient portals:
/// - one active request per doctor+day (requested/scheduled block, others don't)
/// - clinic slots 9:00 AM–5:00 PM every 30 min, past slots disabled same-day.
///
/// "Same doctor" is canonical on owner_id (the appointment's doctor
/// reference). The display-name snapshot is a fallback for legacy local
/// rows that carry no owner id — names drift on profile edits, ids don't.
bool hasActiveBooking({
  required List<Appointment> existing,
  required String doctorId,
  String doctorName = '',
  required String dateIso,
}) {
  return existing.any((a) {
    final sameDoctor =
        (a.ownerId != null && a.ownerId!.isNotEmpty)
            ? a.ownerId == doctorId
            : a.doctor == doctorName;
    return sameDoctor &&
        a.dateIso == dateIso &&
        (a.status == 'requested' || a.status == 'scheduled');
  });
}

List<TimeOfDay> clinicSlots() => [
      for (int m = 9 * 60; m <= 17 * 60; m += 30)
        TimeOfDay(hour: m ~/ 60, minute: m % 60),
    ];

bool isSlotDisabled(TimeOfDay slot, DateTime day, DateTime now) {
  final isToday =
      day.year == now.year && day.month == now.month && day.day == now.day;
  if (!isToday) return false;
  return (slot.hour * 60 + slot.minute) <=
      (now.hour * 60 + now.minute) + 30;
}

Appointment _appt(String doctor, String iso, String status,
        {String? ownerId}) =>
    Appointment(
      id: 'x',
      patientName: 'P',
      date: iso,
      dateIso: iso,
      time: '10:00 AM',
      reason: 'Checkup',
      doctor: doctor,
      status: status,
      ownerId: ownerId,
    );

void main() {
  group('Duplicate booking guard', () {
    test('blocks second active request same doctor+day', () {
      final existing = [_appt('Dr. A', '2026-06-20', 'requested')];
      expect(
          hasActiveBooking(
              existing: existing,
              doctorId: '',
              doctorName: 'Dr. A',
              dateIso: '2026-06-20'),
          isTrue);
    });

    test('allows after cancel/complete, other doctor, other day', () {
      expect(
          hasActiveBooking(
            existing: [_appt('Dr. A', '2026-06-20', 'cancelled')],
            doctorId: '',
            doctorName: 'Dr. A',
            dateIso: '2026-06-20',
          ),
          isFalse);
      expect(
          hasActiveBooking(
            existing: [_appt('Dr. A', '2026-06-20', 'completed')],
            doctorId: '',
            doctorName: 'Dr. A',
            dateIso: '2026-06-20',
          ),
          isFalse);
      expect(
          hasActiveBooking(
            existing: [_appt('Dr. A', '2026-06-20', 'scheduled')],
            doctorId: '',
            doctorName: 'Dr. B',
            dateIso: '2026-06-20',
          ),
          isFalse);
      expect(
          hasActiveBooking(
            existing: [_appt('Dr. A', '2026-06-20', 'scheduled')],
            doctorId: '',
            doctorName: 'Dr. A',
            dateIso: '2026-06-21',
          ),
          isFalse);
    });

    test('matches canonical owner id even when the name drifted', () {
      // Doctor renamed their profile after the first booking: the stored
      // snapshot still says "Dr. Old", the directory now says "Dr. New".
      final existing = [
        _appt('Dr. Old', '2026-06-20', 'requested', ownerId: 'doc-1'),
      ];
      expect(
          hasActiveBooking(
            existing: existing,
            doctorId: 'doc-1',
            doctorName: 'Dr. New',
            dateIso: '2026-06-20',
          ),
          isTrue);
    });

    test('same display name, different owner id is a different doctor', () {
      final existing = [
        _appt('Dr. Smith', '2026-06-20', 'scheduled', ownerId: 'doc-1'),
      ];
      expect(
          hasActiveBooking(
            existing: existing,
            doctorId: 'doc-2',
            doctorName: 'Dr. Smith',
            dateIso: '2026-06-20',
          ),
          isFalse);
    });
  });

  group('Appointment.isSameDoctor (canonical owner id)', () {
    test('same owner id wins over drifted display names', () {
      final a = _appt('Dr. Old', '2026-06-20', 'requested', ownerId: 'doc-1');
      final b = _appt('Dr. New', '2026-06-21', 'requested', ownerId: 'doc-1');
      expect(a.isSameDoctor(b), isTrue);
    });

    test('different owner ids are different doctors', () {
      final a = _appt('Dr. Smith', '2026-06-20', 'requested', ownerId: 'doc-1');
      final b = _appt('Dr. Smith', '2026-06-20', 'requested', ownerId: 'doc-2');
      expect(a.isSameDoctor(b), isFalse);
    });

    test('legacy rows without owner ids fall back to names', () {
      final a = _appt('Dr. A', '2026-06-20', 'requested');
      final b = _appt('Dr. A', '2026-06-21', 'requested');
      final c = _appt('Dr. B', '2026-06-20', 'requested');
      expect(a.isSameDoctor(b), isTrue);
      expect(a.isSameDoctor(c), isFalse);
    });
  });

  group('Clinic slots', () {
    test('17 half-hour slots from 9:00 to 17:00', () {
      final slots = clinicSlots();
      expect(slots.length, 17);
      expect(slots.first, const TimeOfDay(hour: 9, minute: 0));
      expect(slots.last, const TimeOfDay(hour: 17, minute: 0));
    });

    test('past slots disabled same-day, all open future day', () {
      final day = DateTime(2026, 6, 20);
      final now = DateTime(2026, 6, 20, 10, 0); // 10:00 AM
      expect(isSlotDisabled(const TimeOfDay(hour: 9, minute: 30), day, now),
          isTrue);
      // 30-min buffer: 10:30 is still too soon at 10:00.
      expect(isSlotDisabled(const TimeOfDay(hour: 10, minute: 30), day, now),
          isTrue);
      expect(isSlotDisabled(const TimeOfDay(hour: 11, minute: 0), day, now),
          isFalse);
      final tomorrow = DateTime(2026, 6, 21);
      expect(isSlotDisabled(const TimeOfDay(hour: 9, minute: 0), tomorrow, now),
          isFalse);
    });
  });
}
