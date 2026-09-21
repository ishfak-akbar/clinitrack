import 'package:clinitrack/repositories/auth_repository.dart';
import 'package:clinitrack/screens/admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DoctorApplicationEntry', () {
    test('specialtyLine prefers the array, falls back to single', () {
      const withArray = DoctorApplicationEntry(
        id: 'a',
        name: 'Dr. A',
        specialty: 'Surgery',
        specialties: ['Surgery', 'ENT'],
      );
      expect(withArray.specialtyLine, 'Surgery, ENT');

      const legacy = DoctorApplicationEntry(
        id: 'b',
        name: 'Dr. B',
        specialty: 'Cardiology',
      );
      expect(legacy.specialtyLine, 'Cardiology');

      const empty = DoctorApplicationEntry(id: 'c', name: 'Dr. C');
      expect(empty.specialtyLine, isEmpty);
    });
  });

  group('RejectReasonDialog', () {
    Future<void> pumpDialog(WidgetTester tester,
        {required ValueChanged<String> onSubmitted}) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => showDialog<String>(
                context: context,
                builder: (_) => const RejectReasonDialog(),
              ).then((reason) {
                if (reason != null) onSubmitted(reason);
              }),
              child: const Text('Open'),
            );
          },
        ))),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('blocks empty reasons', (tester) async {
      var submitted = false;
      await pumpDialog(tester, onSubmitted: (_) => submitted = true);

      await tester.tap(find.text('Reject'));
      await tester.pump();

      expect(
        find.text('A reason is required — the doctor will see it.'),
        findsOneWidget,
      );
      expect(submitted, isFalse);
    });

    testWidgets('returns the trimmed reason', (tester) async {
      String? result;
      await pumpDialog(tester, onSubmitted: (r) => result = r);

      await tester.enterText(find.byType(TextField), '  Bad license  ');
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      expect(result, 'Bad license');
    });
  });
}
