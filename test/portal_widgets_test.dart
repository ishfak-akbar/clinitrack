import 'package:clinitrack/repositories/auth_repository.dart';
import 'package:clinitrack/widgets/doctor_card.dart';
import 'package:clinitrack/widgets/patient_bottom_nav.dart';
import 'package:clinitrack/widgets/status_chip.dart';
import 'package:clinitrack/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('UserAvatar (per-user, no shared stock photo)', () {
    testWidgets('shows initials derived from name', (tester) async {
      await tester.pumpWidget(_wrap(const UserAvatar(
        avatarUrl: '',
        name: 'Sarah Rahman',
        radius: 24,
      )));
      expect(find.text('SR'), findsOneWidget);
    });

    testWidgets('different users get different initials', (tester) async {
      await tester.pumpWidget(_wrap(const UserAvatar(
        avatarUrl: '',
        name: 'Tanvir Ahmed',
        radius: 24,
      )));
      expect(find.text('TA'), findsOneWidget);
      expect(find.text('SR'), findsNothing);
    });

    testWidgets('single-word name shows one initial', (tester) async {
      await tester.pumpWidget(
          _wrap(const UserAvatar(avatarUrl: '', name: 'Rahim', radius: 24)));
      expect(find.text('R'), findsOneWidget);
    });

    testWidgets('editable shows camera badge and fires onTap',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(UserAvatar(
        avatarUrl: '',
        name: 'A B',
        radius: 24,
        editable: true,
        onTap: () => tapped = true,
      )));
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      await tester.tap(find.byType(UserAvatar));
      expect(tapped, isTrue);
    });
  });

  group('DoctorCard (banner + profile for patients)', () {
    const doctor = DoctorDirectoryEntry(
      id: 'd1',
      name: 'Dr. Sarah Rahman',
      specialty: 'Cardiology',
      qualifications: 'MBBS, MD',
      experienceYears: '8',
      clinicAddress: 'Zindabazar, Sylhet',
      bio: 'Heart care specialist.',
    );

    testWidgets('renders profile details and actions', (tester) async {
      await tester.pumpWidget(_wrap(const DoctorCard(doctor: doctor)));
      expect(find.text('Dr. Sarah Rahman'), findsOneWidget);
      expect(find.text('Cardiology'), findsOneWidget);
      expect(find.textContaining('8 yrs exp'), findsOneWidget);
      expect(find.text('Zindabazar, Sylhet'), findsOneWidget);
      expect(find.text('View profile'), findsOneWidget);
      expect(find.text('Book'), findsOneWidget);
    });

    testWidgets('selected state shows badge and label', (tester) async {
      await tester.pumpWidget(
          _wrap(const DoctorCard(doctor: doctor, selected: true)));
      expect(find.text('Selected'), findsWidgets);
    });

    testWidgets('tap Book calls onSelect, tap card opens profile',
        (tester) async {
      var selected = false;
      var viewed = false;
      await tester.pumpWidget(_wrap(DoctorCard(
        doctor: doctor,
        onSelect: () => selected = true,
        onViewProfile: () => viewed = true,
      )));
      await tester.tap(find.text('Book'));
      expect(selected, isTrue);
      await tester.tap(find.text('View profile'));
      expect(viewed, isTrue);
    });

    testWidgets('renders verification credentials on card and sheet',
        (tester) async {
      const verified = DoctorDirectoryEntry(
        id: 'd9',
        name: 'Dr. Verified Example',
        specialty: 'Surgery',
        experienceYears: '10',
        title: 'Surgeon',
        chamberName: 'City Surgical Clinic',
        degree: 'MBBS',
        graduatingInstitution: 'Dhaka Medical College',
        graduationYear: '2012',
        specialties: ['Surgery', 'General Physician'],
      );
      await tester.pumpWidget(
          _wrap(const DoctorCard(doctor: verified)));
      expect(find.text('Surgeon'), findsOneWidget);
      expect(find.text('City Surgical Clinic'), findsOneWidget);

      showDoctorProfileSheet(
        tester.element(find.byType(DoctorCard)),
        verified,
      );
      await tester.pumpAndSettle();
      expect(find.text('MBBS'), findsOneWidget);
      expect(
        find.textContaining('Dhaka Medical College'),
        findsOneWidget,
      );
      expect(
        find.text('Surgery, General Physician'),
        findsOneWidget,
      );
    });
  });

  group('StatusChip (one language for both portals)', () {
    test('labels map to patient-friendly wording', () {
      expect(StatusChip.labelFor('scheduled'), 'Confirmed');
      expect(StatusChip.labelFor('completed'), 'Completed');
      expect(StatusChip.labelFor('cancelled'), 'Declined');
      expect(StatusChip.labelFor('requested'), 'Awaiting review');
    });

    testWidgets('renders label for each status', (tester) async {
      for (final entry in {
        'scheduled': 'Confirmed',
        'requested': 'Awaiting review',
        'cancelled': 'Declined',
      }.entries) {
        await tester.pumpWidget(
            _wrap(StatusChip(status: entry.key)));
        expect(find.text(entry.value), findsOneWidget);
      }
    });
  });

  group('PatientBottomNav (parity with doctor nav)', () {
    testWidgets('shows selected destination label + all icons',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(bottomNavigationBar: PatientBottomNav(currentIndex: 1)),
      ));
      // Selected pill shows its label; unselected pills show icons only.
      expect(find.text('Book'), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
      expect(find.byIcon(Icons.medication_outlined), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('each tab shows its label when selected', (tester) async {
      const labels = ['Home', 'Book', 'Rx', 'Reminders'];
      for (var i = 0; i < labels.length; i++) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              bottomNavigationBar: PatientBottomNav(currentIndex: i)),
        ));
        expect(find.text(labels[i]), findsOneWidget);
      }
    });

    testWidgets('tapping Book icon navigates to /patient-book',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        initialRoute: '/patient-home',
        routes: {
          '/patient-home': (_) => const Scaffold(
              bottomNavigationBar: PatientBottomNav(currentIndex: 0)),
          '/patient-book': (_) =>
              const Scaffold(body: Text('book-screen-marker')),
          '/patient-prescriptions': (_) =>
              const Scaffold(body: Text('rx-marker')),
          '/patient-reminders': (_) =>
              const Scaffold(body: Text('reminders-marker')),
        },
      ));
      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      expect(find.text('book-screen-marker'), findsOneWidget);
    });
  });
}
