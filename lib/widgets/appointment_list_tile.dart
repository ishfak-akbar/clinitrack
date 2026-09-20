import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

enum AppointmentStatus { scheduled, completed, requested, cancelled }

class AppointmentListTile extends StatelessWidget {
  final String patientName;
  final String time;
  final String reason;
  final AppointmentStatus status;
  final ValueChanged<AppointmentStatus> onStatusChanged;
  final VoidCallback onTap;

  const AppointmentListTile({
    super.key,
    required this.patientName,
    required this.time,
    required this.reason,
    required this.status,
    required this.onStatusChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = status == AppointmentStatus.completed;
    final bool isRequested = status == AppointmentStatus.requested;
    final bool isCancelled = status == AppointmentStatus.cancelled;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;
    // Status pill that stays readable in both themes.
    final pillColor = isCompleted
        ? AppColors.successGreen
        : isCancelled
            ? (isDark
                ? AppColors.darkTextSecondary
                : AppColors.textGray)
            : AppColors.warningAmber;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: accent.withValues(alpha: 0.12),
          child: Text(
            patientName.isNotEmpty ? patientName.substring(0, 1) : '?',
            style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        title: Text(patientName, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text('$time · $reason'),
        trailing: isRequested
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Approve',
                    icon: const Icon(Icons.check_circle,
                        color: AppColors.successGreen),
                    onPressed: () => onStatusChanged(
                      AppointmentStatus.scheduled,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Decline',
                    icon: const Icon(Icons.cancel_outlined,
                        color: AppColors.errorRed),
                    onPressed: () => onStatusChanged(
                      AppointmentStatus.cancelled,
                    ),
                  ),
                ],
              )
            : GestureDetector(
                onTap: () => onStatusChanged(
                  isCompleted
                      ? AppointmentStatus.scheduled
                      : AppointmentStatus.completed,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: pillColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: pillColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isCompleted
                        ? 'Completed'
                        : isCancelled
                            ? 'Cancelled'
                            : 'Scheduled',
                    style: TextStyle(
                      color: pillColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}