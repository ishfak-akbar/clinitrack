import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/expandable_record_section.dart';

class PatientDetailsScreen extends StatelessWidget {
  const PatientDetailsScreen({super.key});

  static const List<Map<String, String>> _visitHistory = [
    {'date': '18 May 2025', 'reason': 'Fever and headache', 'doctor': 'Dr. Sarah Ahmed'},
    {'date': '10 Apr 2025', 'reason': 'Cough and cold', 'doctor': 'Dr. James Wilson'},
    {'date': '05 Mar 2025', 'reason': 'Stomach pain', 'doctor': 'Dr. Emily Clark'},
  ];

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 40),
        title: const Text('Delete Patient'),
        content: const Text(
          "Are you sure you want to delete John Doe's record? This action cannot be undone.",
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient record deleted')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.screenTintedBackground,
      appBar: AppBar(
        backgroundColor: AppColors.screenTintedBackground,
        title: const Text('Medical Record'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- Patient header ----------
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryTealLight,
                child: Text('J', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700, fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('John Doe', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text('28 yrs, Male  |  A+', style: Theme.of(context).textTheme.bodyMedium),
                  Text('Phone: 01912345678', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/add-prescription'),
                  icon: const Icon(Icons.medication_outlined, size: 18),
                  label: const Text('Prescribe'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/follow-up'),
                  icon: const Icon(Icons.event_available_outlined, size: 18),
                  label: const Text('Follow-up'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ---------- Visit history ----------
          Text('Visit History', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ..._visitHistory.map((visit) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primaryTeal),
                title: Text(visit['date']!, style: Theme.of(context).textTheme.titleMedium),
                subtitle: Text('${visit['reason']}\n${visit['doctor']}'),
                isThreeLine: true,
              ),
            );
          }),
          const SizedBox(height: 16),

          // ---------- Expandable sections ----------
          const ExpandableRecordSection(
            title: 'Prescriptions',
            items: ['Paracetamol 500mg — Daily, 5 Days', 'Amoxicillin 250mg — Twice a day, 7 Days'],
          ),
          const ExpandableRecordSection(
            title: 'Diagnoses',
            items: ['Seasonal flu — 18 May 2025', 'Mild gastritis — 05 Mar 2025'],
          ),
          const ExpandableRecordSection(
            title: 'Lab Reports',
            items: [],
          ),
        ],
      ),
    );
  }
}