import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

enum AppointmentStatus { scheduled, completed }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

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
        trailing: GestureDetector(
          onTap: () => onStatusChanged(
            isCompleted ? AppointmentStatus.scheduled : AppointmentStatus.completed,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFFE3F6ED) : const Color(0xFFFDF0DC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isCompleted ? 'Completed' : 'Scheduled',
              style: TextStyle(
                color: isCompleted ? AppColors.successGreen : AppColors.warningAmber,
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