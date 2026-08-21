import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class DashboardStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBackground;

  const DashboardStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppColors.primaryTeal,
    this.iconBackground = AppColors.primaryTealLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodySmall, maxLines: 2),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
        ],
      ),
    );
  }
}