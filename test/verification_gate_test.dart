import 'package:clinitrack/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveHomeRoute', () {
    test('patients go to the portal regardless of status', () {
      expect(
        resolveHomeRoute(role: 'Patient', verificationStatus: 'approved'),
        '/patient-home',
      );
      expect(
        resolveHomeRoute(role: 'Patient', verificationStatus: 'pending'),
        '/patient-home',
      );
    });

    test('approved doctors go to the dashboard', () {
      expect(
        resolveHomeRoute(role: 'Doctor', verificationStatus: 'approved'),
        '/dashboard',
      );
    });

    test('pending and rejected doctors go to the waiting room', () {
      expect(
        resolveHomeRoute(role: 'Doctor', verificationStatus: 'pending'),
        '/verification-pending',
      );
      expect(
        resolveHomeRoute(role: 'Doctor', verificationStatus: 'rejected'),
        '/verification-pending',
      );
    });
  });

  group('needsVerificationGate', () {
    test('only unapproved doctors are gated', () {
      expect(
        needsVerificationGate(role: 'Doctor', verificationStatus: 'pending'),
        isTrue,
      );
      expect(
        needsVerificationGate(role: 'Doctor', verificationStatus: 'rejected'),
        isTrue,
      );
      expect(
        needsVerificationGate(role: 'Doctor', verificationStatus: 'approved'),
        isFalse,
      );
    });

    test('patients and admins are never gated', () {
      expect(
        needsVerificationGate(role: 'Patient', verificationStatus: 'pending'),
        isFalse,
      );
      expect(
        needsVerificationGate(role: 'Admin', verificationStatus: 'pending'),
        isFalse,
      );
    });
  });
}
