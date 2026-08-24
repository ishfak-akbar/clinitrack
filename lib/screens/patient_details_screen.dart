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
          const SizedBox(height: 7,),
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
      appBar: AppBar(
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
                backgroundColor: AppColors.primaryTeal,
                child: Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nahian', style: Theme.of(context).textTheme.titleLarge),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  for (int i = 0; i < _visitHistory.length; i++) ...[
                    _VisitHistoryRow(visit: _visitHistory[i]),
                    if (i != _visitHistory.length - 1) const Divider(),
                  ],
                ],
              ),
            ),
          ),
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
class _VisitHistoryRow extends StatelessWidget {
  final Map<String, String> visit;

  const _VisitHistoryRow({required this.visit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today_outlined, color: AppColors.primaryTeal),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(visit['date']!, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text('${visit['reason']}', style: Theme.of(context).textTheme.bodyMedium),
                Text('${visit['doctor']}', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}