import 'package:clinitrack/models/appointment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Booking business rules shared by doctor + patient portals:
/// - one active request per doctor+day (requested/scheduled block, others don't)
/// - clinic slots 9:00 AM–5:00 PM every 30 min, past slots disabled same-day.
bool hasActiveBooking({
  required List<Appointment> existing,
  required String doctor,
  required String dateIso,
}) {
  return existing.any((a) =>
      a.doctor == doctor &&
      a.dateIso == dateIso &&
      (a.status == 'requested' || a.status == 'scheduled'));
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

Appointment _appt(String doctor, String iso, String status) => Appointment(
      id: 'x',
      patientName: 'P',
      date: iso,
      dateIso: iso,
      time: '10:00 AM',
      reason: 'Checkup',
      doctor: doctor,
      status: status,
    );

void main() {
  group('Duplicate booking guard', () {
    test('blocks second active request same doctor+day', () {
      final existing = [_appt('Dr. A', '2026-06-20', 'requested')];
      expect(
          hasActiveBooking(
              existing: existing, doctor: 'Dr. A', dateIso: '2026-06-20'),
          isTrue);
    });

    test('allows after cancel/complete, other doctor, other day', () {
      expect(
          hasActiveBooking(
            existing: [_appt('Dr. A', '2026-06-20', 'cancelled')],
            doctor: 'Dr. A',
            dateIso: '2026-06-20',
          ),
          isFalse);
      expect(
          hasActiveBooking(
            existing: [_appt('Dr. A', '2026-06-20', 'completed')],
            doctor: 'Dr. A',
            dateIso: '2026-06-20',
          ),
          isFalse);
      expect(
          hasActiveBooking(
            existing: [_appt('Dr. A', '2026-06-20', 'scheduled')],
            doctor: 'Dr. B',
            dateIso: '2026-06-20',
          ),
          isFalse);
      expect(
          hasActiveBooking(
            existing: [_appt('Dr. A', '2026-06-20', 'scheduled')],
            doctor: 'Dr. A',
            dateIso: '2026-06-21',
          ),
          isFalse);
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
