import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class ThemedChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const ThemedChoiceChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: accent.withValues(alpha: 0.15),
      backgroundColor: isDark ? AppColors.darkCard : Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? accent : theme.textTheme.bodyLarge?.color,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}