import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';

/// Part 5: patient booking — fleshed out next (doctors directory + request).
class PatientBookScreen extends StatelessWidget {
  const PatientBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Book visit')),
      body: const Center(child: Text('Booking coming next.')),
    );
  }
}
