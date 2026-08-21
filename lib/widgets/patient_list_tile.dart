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
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryTealLight,
          child: Text(
            name.isNotEmpty ? name.substring(0, 1) : '?',
            style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text('$age yrs, $gender\nLast visit: $lastVisit'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right, color: AppColors.iconGray),
      ),
    );
  }
}