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

  Widget _navItem(BuildContext context, {required IconData icon, required String label, required int index}) {
    final bool isSelected = index == currentIndex;
    final Color color = isSelected ? AppColors.primaryTeal : AppColors.iconGray;
    return Expanded(
      child: InkWell(
        onTap: () => _onTap(context, index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: AppColors.cardWhite,
      padding: EdgeInsets.zero,
      height: 64,
      child: Row(
        children: [
          _navItem(context, icon: Icons.dashboard_outlined, label: 'Dashboard', index: 0),
          _navItem(context, icon: Icons.people_outline, label: 'Patients', index: 1),
          const Expanded(child: SizedBox()),
          _navItem(context, icon: Icons.event_note_outlined, label: 'Appointments', index: 2),
          _navItem(context, icon: Icons.more_horiz, label: 'More', index: 3),
        ],
      ),
    );
  }
}