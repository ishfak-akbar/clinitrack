import 'package:flutter/material.dart';

/// Shared sticky primary action used in the bottomNavigationBar slot
/// across every form screen. Styling comes from the app theme so all
/// primary actions look identical; only loading state is handled here.
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isSaving ? null : onPressed,
            child: isSaving
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Theme.of(context).colorScheme.onPrimary,
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