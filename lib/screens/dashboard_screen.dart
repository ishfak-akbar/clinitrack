import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/app_add_fab.dart';
import '../providers/appointment_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<AppointmentProvider>().appointments;
    final visibleAppointments = appointments.take(4).toList();

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.screenTintedBackground,
      appBar: AppBar(
        backgroundColor: AppColors.screenTintedBackground,
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
        padding: const EdgeInsets.all(16),
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
                  label: "Today's Appointments",
                  value: '8',
                  iconColor: Color(0xFF3B82F6),
                  iconBackground: Color(0xFFE0EBFD),
                  cardBackground: Color(0xFFF3F8FF),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.people_outline,
                  label: 'Total     Patients',
                  value: '245',
                  iconColor: AppColors.successGreen,
                  iconBackground: Color(0xFFE3F6ED),
                  cardBackground: Color(0xFFF2FBF6),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.schedule_outlined,
                  label: 'Follow-ups  Due',
                  value: '12',
                  iconColor: AppColors.errorRed,
                  iconBackground: Color(0xFFFCE8E8),
                  cardBackground: Color(0xFFFFF5F3),
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
    return ListTile(
      onTap: () => Navigator.of(context).pushNamed('/patient-details'),
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryTealLight,
        child: Text(
          appointment.patientName.isNotEmpty ? appointment.patientName.substring(0, 1) : '?',
          style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(appointment.patientName, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text('${appointment.time} · ${appointment.reason}'),
      trailing: const Icon(Icons.chevron_right, color: AppColors.iconGray),
    );
  }
}