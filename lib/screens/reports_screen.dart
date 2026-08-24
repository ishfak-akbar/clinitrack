import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/dashboard_stat_card.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Clinic Overview', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),

          Row(
            children: const [
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.people_outline,
                  label: 'Total Patients',
                  value: '245',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.event_note_outlined,
                  label: 'Appointments',
                  value: '58',
                  iconColor: AppColors.successGreen,
                  iconBackground: Color(0xFFE3F6ED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.medication_outlined,
                  label: 'Prescriptions',
                  value: '132',
                  iconColor: AppColors.warningAmber,
                  iconBackground: Color(0xFFFDF0DC),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.schedule_outlined,
                  label: 'Follow-ups Due',
                  value: '12',
                  iconColor: AppColors.errorRed,
                  iconBackground: Color(0xFFFCE8E8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text('Patient Demographics', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _demographicRow(context, label: 'Male', value: '138', percent: 0.56),
                  const SizedBox(height: 14),
                  _demographicRow(context, label: 'Female', value: '102', percent: 0.42),
                  const SizedBox(height: 14),
                  _demographicRow(context, label: 'Other', value: '5', percent: 0.02),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text('Blood Group Distribution', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 11,
                runSpacing: 11,
                children: const [
                  _BloodGroupChip(label: 'A+', count: '48'),
                  _BloodGroupChip(label: 'A-', count: '12'),
                  _BloodGroupChip(label: 'B+', count: '56'),
                  _BloodGroupChip(label: 'B-', count: '9'),
                  _BloodGroupChip(label: 'O+', count: '78'),
                  _BloodGroupChip(label: 'O-', count: '14'),
                  _BloodGroupChip(label: 'AB+', count: '21'),
                  _BloodGroupChip(label: 'AB-', count: '7'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _demographicRow(BuildContext context, {required String label, required String value, required double percent}) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: AppColors.borderGray,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _BloodGroupChip extends StatelessWidget {
  final String label;
  final String count;

  const _BloodGroupChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryTealLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 2),
          Text(count, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}