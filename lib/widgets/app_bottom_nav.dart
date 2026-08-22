import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../utils/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  void _onDestinationTap(BuildContext context, int index) {
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

  Widget _pillItem(BuildContext context, {required IconData icon, required String label, required int index}) {
    final bool isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => _onDestinationTap(context, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(34),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: isSelected ? AppColors.cardWhite : AppColors.iconGray),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: AppColors.cardWhite, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 78,
        borderRadius: 36,
        blur: 16,
        alignment: Alignment.center,
        border: 1.5,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardWhite.withValues(alpha: 0.55),
            AppColors.cardWhite.withValues(alpha: 0.35),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.6),
            Colors.white.withValues(alpha: 0.2),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _pillItem(context, icon: Icons.dashboard_outlined, label: 'Dashboard', index: 0),
                _pillItem(context, icon: Icons.people_outline, label: 'Patients', index: 1),
                _pillItem(context, icon: Icons.event_note_outlined, label: 'Appointments', index: 2),
                _pillItem(context, icon: Icons.more_horiz, label: 'More', index: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}