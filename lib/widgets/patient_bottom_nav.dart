import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../utils/app_colors.dart';
import 'app_add_fab.dart';

/// Patient counterpart of [AppBottomNav] — same glass pill style so both
/// portals feel like one app. Index mapping:
/// 0 = Home (/patient-home), 1 = Book (/patient-book),
/// 2 = Prescriptions (/patient-prescriptions), 3 = Reminders (/patient-reminders).
class PatientBottomNav extends StatelessWidget {
  final int currentIndex;

  const PatientBottomNav({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/patient-home');
        break;
      case 1:
        // Push (not replace): Book is a form, so the AppBar back button
        // must return to the tab the patient came from.
        Navigator.of(context).pushNamed('/patient-book');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/patient-prescriptions');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/patient-reminders');
        break;
    }
  }

  Widget _pill(BuildContext context,
      {required IconData icon, required String label, required int index}) {
    final bool isSelected = index == currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;
    final unselectedColor =
        isDark ? AppColors.darkTextSecondary : AppColors.iconGray;

    return GestureDetector(
      onTap: () => _onTap(context, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(34),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? (isDark ? AppColors.darkBackground : AppColors.cardWhite)
                  : unselectedColor,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? AppColors.darkBackground : AppColors.cardWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.30 : 0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 78,
            borderRadius: 36,
            blur: 18,
            alignment: Alignment.center,
            border: 1.2,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.darkCard.withValues(alpha: 0.75),
                      AppColors.darkSurface.withValues(alpha: 0.55),
                    ]
                  : [
                      AppColors.cardWhite.withValues(alpha: 0.55),
                      AppColors.cardWhite.withValues(alpha: 0.35),
                    ],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.primaryTealAccent.withValues(alpha: 0.55),
                      AppColors.darkBorder.withValues(alpha: 0.4),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.7),
                      AppColors.primaryTeal.withValues(alpha: 0.15),
                    ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _pill(context,
                        icon: Icons.home_outlined, label: 'Home', index: 0),
                    _pill(context,
                        icon: Icons.calendar_month_outlined,
                        label: 'Book',
                        index: 1),
                    _pill(context,
                        icon: Icons.medication_outlined,
                        label: 'Rx',
                        index: 2),
                    _pill(context,
                        icon: Icons.notifications_outlined,
                        label: 'Reminders',
                        index: 3),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared FAB offset so patient FABs float above the glass nav,
/// matching the doctor portal.
const patientFabLocation = AppFabAboveNavLocation();
