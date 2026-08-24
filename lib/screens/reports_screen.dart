import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/dashboard_stat_card.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
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
                  iconColor: AppColors.primaryTeal,
                  lightIconBackground: AppColors.primaryTealLight,
                  lightCardBackground: Color(0xFFF2FBF6),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.event_note_outlined,
                  label: 'Appointments',
                  value: '58',
                  iconColor: AppColors.successGreen,
                  lightIconBackground: Color(0xFFE3F6ED),
                  lightCardBackground: Color(0xFFF2FBF6),
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
                  lightIconBackground: Color(0xFFFDF0DC),
                  lightCardBackground: Color(0xFFFFF8EE),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.schedule_outlined,
                  label: 'Follow-ups Due',
                  value: '12',
                  iconColor: AppColors.followUpOrange,
                  lightIconBackground: AppColors.followUpOrangeLight,
                  lightCardBackground: AppColors.followUpOrangeCard,
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
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Expanded(child: _BloodGroupChip(label: 'A+', count: '48')),
                      SizedBox(width: 10),
                      Expanded(child: _BloodGroupChip(label: 'A-', count: '12')),
                      SizedBox(width: 10),
                      Expanded(child: _BloodGroupChip(label: 'B+', count: '56')),
                      SizedBox(width: 10),
                      Expanded(child: _BloodGroupChip(label: 'B-', count: '9')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Expanded(child: _BloodGroupChip(label: 'O+', count: '78')),
                      SizedBox(width: 10),
                      Expanded(child: _BloodGroupChip(label: 'O-', count: '14')),
                      SizedBox(width: 10),
                      Expanded(child: _BloodGroupChip(label: 'AB+', count: '21')),
                      SizedBox(width: 10),
                      Expanded(child: _BloodGroupChip(label: 'AB-', count: '7')),
                    ],
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.35 : 0.22),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }
}