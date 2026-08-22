import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class PatientListTile extends StatelessWidget {
  final String name;
  final String age;
  final String gender;
  final String lastVisit;
  final VoidCallback onTap;

  const PatientListTile({
    super.key,
    required this.name,
    required this.age,
    required this.gender,
    required this.lastVisit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryTealLight,
                child: Text(
                  name.isNotEmpty ? name.substring(0, 1) : '?',
                  style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text('$age yrs, $gender', style: Theme.of(context).textTheme.bodyMedium),
                    Text('Last visit: $lastVisit', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.iconGray),
            ],
          ),
        ),
      ),
    );
  }
}