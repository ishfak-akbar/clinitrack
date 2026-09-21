import 'package:clinitrack/screens/edit_profile_screen.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _base() => ['Surgeon', 'MBBS', 'DMC', '2012', 'L-1', 'FCPS', 'Surgery'];

void main() {
  group('doctorCredentialsChanged', () {
    test('unchanged credentials stay approved', () {
      expect(
        doctorCredentialsChanged(
          values: _base(),
          stored: _base(),
          specialties: ['Surgery', 'ENT'],
          storedSpecialties: ['ENT', 'Surgery'],
        ),
        isFalse,
      );
    });

    test('any credential change triggers re-review', () {
      for (var i = 0; i < _base().length; i++) {
        final changed = _base();
        changed[i] = '${changed[i]}*';
        expect(
          doctorCredentialsChanged(
            values: changed,
            stored: _base(),
            specialties: const ['Surgery'],
            storedSpecialties: const ['Surgery'],
          ),
          isTrue,
          reason: 'field $i should trigger re-review',
        );
      }
    });

    test('specialty edits are order- and case-insensitive', () {
      expect(
        doctorCredentialsChanged(
          values: _base(),
          stored: _base(),
          specialties: ['surgery'],
          storedSpecialties: ['Surgery'],
        ),
        isFalse,
      );
      expect(
        doctorCredentialsChanged(
          values: _base(),
          stored: _base(),
          specialties: ['Surgery', 'ENT'],
          storedSpecialties: ['Surgery'],
        ),
        isTrue,
      );
    });

    test('whitespace-only differences are ignored', () {
      final padded = _base().map((s) => '  $s  ').toList();
      expect(
        doctorCredentialsChanged(
          values: padded,
          stored: _base(),
          specialties: const ['Surgery'],
          storedSpecialties: const ['Surgery'],
        ),
        isFalse,
      );
    });
  });
}
