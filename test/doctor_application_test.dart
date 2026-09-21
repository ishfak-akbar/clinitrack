import 'package:clinitrack/providers/auth_provider.dart';
import 'package:clinitrack/screens/doctor_application_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('parseGraduationYear', () {
    test('accepts valid years', () {
      expect(parseGraduationYear('2018'), 2018);
      expect(parseGraduationYear('  2000  '), 2000);
    });

    test('rejects non-numeric, too old, and future years', () {
      expect(parseGraduationYear(''), isNull);
      expect(parseGraduationYear('MBBS'), isNull);
      expect(parseGraduationYear('1949'), isNull);
      expect(parseGraduationYear('${DateTime.now().year + 1}'), isNull);
    });
  });

  group('normalizeSpecialties', () {
    test('trims, drops empties, de-duplicates case-insensitively', () {
      expect(
        normalizeSpecialties([' Cardiology ', '', 'cardiology', 'Pediatrics']),
        ['Cardiology', 'Pediatrics'],
      );
    });

    test('empty input stays empty', () {
      expect(normalizeSpecialties([]), isEmpty);
      expect(normalizeSpecialties(['  ']), isEmpty);
    });
  });

  test('specialty options list is non-empty', () {
    expect(kSpecialtyOptions, isNotEmpty);
  });

  // Regression: picking an item used to crash with the dropdown
  // "exactly one item with value" assertion, because the rebuilt menu
  // excludes the just-picked specialty while the field kept it as value.
  testWidgets('picking a specialty from the dropdown adds a chip',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
          child: const DoctorApplicationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The specialties card starts below the fold in the test viewport.
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.text('ENT'), findsOneWidget);
    await tester.tap(find.text('ENT'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(InputChip), findsOneWidget);
  });

  group('blankDemoDefault', () {
    test('blanks exact demo placeholders, keeps real values', () {
      expect(blankDemoDefault('MBBS-214578', 'MBBS-214578'), isEmpty);
      expect(blankDemoDefault('  01912345678  ', '01912345678'), isEmpty);
      expect(blankDemoDefault('BMDC-12345', 'MBBS-214578'), 'BMDC-12345');
      expect(blankDemoDefault('', 'MBBS-214578'), isEmpty);
    });
  });
}
