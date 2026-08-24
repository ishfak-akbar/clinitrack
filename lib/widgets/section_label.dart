import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final IconData? icon;

  const SectionLabel(this.text, {this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: AppColors.primaryTeal,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTeal, // keeps your main color
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}