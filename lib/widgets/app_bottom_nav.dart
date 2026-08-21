import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/dashboard');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/patient-list');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/appointments');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/more');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Patients'),
        BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: 'Appointments'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
      ],
    );
  }
}