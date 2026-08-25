import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/app_add_fab.dart';
import '../providers/appointment_provider.dart';
import '../providers/patient_provider.dart';
import '../widgets/app_scaffold.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<AppointmentProvider>().appointments;
    final visibleAppointments = appointments.take(4).toList();

    return AppScaffold(
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/profile'),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryTeal,
                child: Icon(Icons.person, color: AppColors.primaryTealLight),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            'Good morning, Dr. Ishfak!',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),

          // ---------- Stat cards ----------
          Row(
            children: const [
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.calendar_today_outlined,
                  label: "Today's\nAppointments",
                  value: '8',
                  iconColor: Color(0xFF3B82F6),
                  lightIconBackground: Color(0xFFE0EBFD),
                  lightCardBackground: Color(0xFFF3F8FF),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.people_outline,
                  label: 'Total\nPatients',
                  value: '245',
                  iconColor: AppColors.successGreen,
                  lightIconBackground: Color(0xFFE3F6ED),
                  lightCardBackground: Color(0xFFF2FBF6),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.schedule_outlined,
                  label: 'Follow-ups\nDue',
                  value: '12',
                  iconColor: AppColors.followUpOrange,
                  lightIconBackground: AppColors.followUpOrangeLight,
                  lightCardBackground: AppColors.followUpOrangeCard,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            "Today's Appointments",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          // ---------- Appointment list ----------
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  for (int i = 0; i < visibleAppointments.length; i++) ...[
                    _AppointmentRow(appointment: visibleAppointments[i]),
                    if (i != visibleAppointments.length - 1) const Divider(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const AppAddFab(routeName: '/add-appointment'),
      floatingActionButtonLocation: const AppFabAboveNavLocation(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  final Appointment appointment;

  const _AppointmentRow({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

    return ListTile(
      onTap: () {
        final allPatients = context.read<PatientProvider>().patients;
        final matching = allPatients.where((p) => p.id == appointment.patientId);
        Navigator.of(context).pushNamed(
          '/patient-details',
          arguments: matching.isNotEmpty ? matching.first : null,
        );
      },
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: accent.withValues(alpha: 0.12),
        child: Text(
          appointment.patientName.isNotEmpty ? appointment.patientName.substring(0, 1) : '?',
          style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      title: Text(appointment.patientName, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text('${appointment.time} · ${appointment.reason}'),
      trailing: const Icon(Icons.chevron_right, color: AppColors.iconGray),
    );
  }
}