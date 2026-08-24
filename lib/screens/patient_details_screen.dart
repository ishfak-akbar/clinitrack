import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/expandable_record_section.dart';
import '../providers/patient_provider.dart';
import 'package:provider/provider.dart';
import '../providers/prescription_provider.dart';

class PatientDetailsScreen extends StatelessWidget {
  const PatientDetailsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 40),
        title: const Text('Delete Patient'),
        content: Text(
          "Are you sure you want to delete ${patient.name}'s record? This action cannot be undone.",
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
        SnackBar(content: Text('${patient.name} deleted')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = ModalRoute.of(context)?.settings.arguments as Patient?;

    if (patient == null) {
      return AppScaffold(
        appBar: AppBar(title: const Text('Medical Record')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No patient record found.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Record'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
            onPressed: () => _confirmDelete(context, patient),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- Patient header ----------
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryTeal,
                child: Text(
                  patient.name.isNotEmpty ? patient.name.substring(0, 1) : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      '${patient.age} yrs, ${patient.gender}  |  ${patient.bloodGroup}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text('Phone: ${patient.contact}', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/add-prescription', arguments: patient),
                  icon: const Icon(Icons.medication_outlined, size: 18),
                  label: const Text('Prescribe'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/follow-up', arguments: patient),
                  icon: const Icon(Icons.event_available_outlined, size: 18),
                  label: const Text('Follow-up'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ---------- Medical History ----------
          Text('Medical History', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                patient.medicalHistory.isEmpty ? 'No medical history recorded.' : patient.medicalHistory,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ---------- Allergies ----------
          Text('Allergies', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: patient.allergies.isEmpty
                    ? Text('No known allergies.', style: Theme.of(context).textTheme.bodyLarge)
                    : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: patient.allergies
                      .map((a) => Chip(
                    label: Text(a, style: TextStyle(fontSize: 13, color: accent)),
                    backgroundColor: accent.withValues(alpha: isDark ? 0.15 : 0.10),
                    side: BorderSide(color: accent.withValues(alpha: isDark ? 0.35 : 0.22)),
                  ))
                      .toList(),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // ---------- Expandable sections ----------
          Consumer<PrescriptionProvider>(
            builder: (context, prescriptionProvider, _) {
              final items = prescriptionProvider
                  .forPatient(patient.id)
                  .map((p) => p.summary)
                  .toList();
              return ExpandableRecordSection(
                title: 'Prescriptions',
                items: items,
              );
            },
          ),
          const ExpandableRecordSection(
            title: 'Visit History',
            items: [],
          ),
        ],
      ),
    );
  }
}