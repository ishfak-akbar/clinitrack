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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryTealLight,
          child: Text(
            patientName.isNotEmpty ? patientName.substring(0, 1) : '?',
            style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700),
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