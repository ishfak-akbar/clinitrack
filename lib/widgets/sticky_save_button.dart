import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Shared sticky "Save" button used in the bottomNavigationBar slot
/// across every "Add ___" form screen. Keeps loading-state spinner
/// and styling consistent and centrally editable.
class StickySaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback? onPressed;
  final String label;

  const StickySaveButton({
    super.key,
    required this.isSaving,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isSaving ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal,
              foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isSaving
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: isDark ? AppColors.darkBackground : Colors.white,
              ),
            )
                : Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}