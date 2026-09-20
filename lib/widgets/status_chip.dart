import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// One shared appointment-status chip for both portals.
///
/// Same labels and colors everywhere: Confirmed / Completed /
/// Declined / Awaiting review — never raw Material colors inline.
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  static String labelFor(String status) => switch (status) {
        'scheduled' => 'Confirmed',
        'completed' => 'Completed',
        'cancelled' => 'Declined',
        'requested' => 'Awaiting review',
        _ => status,
      };

  static Color colorFor(String status, {bool dark = false}) =>
      switch (status) {
        'scheduled' || 'completed' => AppColors.successGreen,
        'cancelled' => AppColors.errorRed,
        'requested' => AppColors.warningAmber,
        _ => dark ? AppColors.darkTextSecondary : AppColors.textGray,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = colorFor(status, dark: isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        labelFor(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
