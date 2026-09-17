import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/stats_service.dart';
import '../utils/app_colors.dart';
import '../widgets/dashboard_stat_card.dart';
import '../providers/appointment_provider.dart';
import '../providers/follow_up_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/stats_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    // Stats are prefetched in splash; refresh on open so numbers are fresh.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    await context.read<StatsProvider>().refresh(
          patients: context.read<PatientProvider>().patients,
          appointments: context.read<AppointmentProvider>().appointments,
          prescriptions: context.read<PrescriptionProvider>().prescriptions,
          followUps: context.read<FollowUpProvider>().followUps,
          medicines: context.read<MedicineProvider>().medicines,
        );
  }

  @override
  Widget build(BuildContext context) {
    final statsState = context.watch<StatsProvider>();
    final stats = statsState.stats;

    return AppScaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Reports')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: statsState.isLoading && stats.totalPatients == 0
            ? ListView(
                padding: const EdgeInsets.all(32),
                children: const [
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (statsState.errorMessage.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_off_outlined,
                                color: AppColors.errorRed),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                statsState.errorMessage,
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            TextButton(
                              onPressed: _refresh,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (statsState.errorMessage.isNotEmpty)
                    const SizedBox(height: 12),
                  Text('Clinic Overview',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DashboardStatCard(
                          icon: Icons.people_outline,
                          label: 'Total Patients',
                          value: '${stats.totalPatients}',
                          iconColor: AppColors.primaryTeal,
                          lightIconBackground: AppColors.primaryTealLight,
                          lightCardBackground: const Color(0xFFF2FBF6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DashboardStatCard(
                          icon: Icons.event_note_outlined,
                          label: 'Appointments',
                          value: '${stats.totalAppointments}',
                          iconColor: AppColors.successGreen,
                          lightIconBackground: const Color(0xFFE3F6ED),
                          lightCardBackground: const Color(0xFFF2FBF6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DashboardStatCard(
                          icon: Icons.medication_outlined,
                          label: 'Prescriptions',
                          value: '${stats.totalPrescriptions}',
                          iconColor: AppColors.warningAmber,
                          lightIconBackground: const Color(0xFFFDF0DC),
                          lightCardBackground: const Color(0xFFFFF8EE),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DashboardStatCard(
                          icon: Icons.schedule_outlined,
                          label: 'Follow-ups Due',
                          value: '${stats.followUpsDue}',
                          iconColor: AppColors.followUpOrange,
                          lightIconBackground:
                              AppColors.followUpOrangeLight,
                          lightCardBackground:
                              AppColors.followUpOrangeCard,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DashboardStatCard(
                          icon: Icons.calendar_today_outlined,
                          label: "Today's\nAppointments",
                          value: '${stats.todayAppointments}',
                          iconColor: const Color(0xFF3B82F6),
                          lightIconBackground: const Color(0xFFE0EBFD),
                          lightCardBackground: const Color(0xFFF3F8FF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DashboardStatCard(
                          icon: Icons.inventory_2_outlined,
                          label: 'Low\nStock',
                          value: '${stats.lowStockMedicines}',
                          iconColor: AppColors.errorRed,
                          lightIconBackground: const Color(0xFFFDE7E7),
                          lightCardBackground: const Color(0xFFFFF3F3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text('Patient Demographics',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _demographicRow(
                            context,
                            label: 'Male',
                            value: '${stats.genderCounts['Male'] ?? 0}',
                            percent: _percent(
                                stats.genderCounts['Male'] ?? 0,
                                stats.totalByGender),
                          ),
                          const SizedBox(height: 14),
                          _demographicRow(
                            context,
                            label: 'Female',
                            value: '${stats.genderCounts['Female'] ?? 0}',
                            percent: _percent(
                                stats.genderCounts['Female'] ?? 0,
                                stats.totalByGender),
                          ),
                          const SizedBox(height: 14),
                          _demographicRow(
                            context,
                            label: 'Other',
                            value: '${stats.genderCounts['Other'] ?? 0}',
                            percent: _percent(
                                stats.genderCounts['Other'] ?? 0,
                                stats.totalByGender),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Blood Group Distribution',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              for (var i = 0; i < 4; i++) ...[
                                if (i > 0) const SizedBox(width: 10),
                                Expanded(
                                  child: _BloodGroupChip(
                                    label: StatsService.bloodGroups[i],
                                    count:
                                        '${stats.bloodGroupCounts[StatsService.bloodGroups[i]] ?? 0}',
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              for (var i = 4; i < 8; i++) ...[
                                if (i > 4) const SizedBox(width: 10),
                                Expanded(
                                  child: _BloodGroupChip(
                                    label: StatsService.bloodGroups[i],
                                    count:
                                        '${stats.bloodGroupCounts[StatsService.bloodGroups[i]] ?? 0}',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
      ),
    );
  }

  double _percent(int part, int total) {
    if (total <= 0) return 0;
    return (part / total).clamp(0.0, 1.0);
  }

  Widget _demographicRow(BuildContext context,
      {required String label,
      required String value,
      required double percent}) {
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
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
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
