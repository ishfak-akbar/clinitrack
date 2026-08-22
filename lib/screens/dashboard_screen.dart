import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/app_add_fab.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const List<Map<String, String>> _appointments = [
    {'time': '09:00 AM', 'name': 'John Doe', 'reason': 'General Checkup'},
    {'time': '10:30 AM', 'name': 'Emily Smith', 'reason': 'Fever & Cold'},
    {'time': '12:00 PM', 'name': 'Michael Brown', 'reason': 'Follow-up'},
    {'time': '02:30 PM', 'name': 'Sarah Johnson', 'reason': 'Consultation'},
  ];

  @override
  Widget build(BuildContext context) {
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
              'Good morning, Dr. Sarah',
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
                SizedBox(width: 12),
                Expanded(
                  child: DashboardStatCard(
                    icon: Icons.people_outline,
                    label: 'Total Patients',
                    value: '245',
                    iconColor: AppColors.successGreen,
                    iconBackground: Color(0xFFE3F6ED),
                    cardBackground: Color(0xFFF2FBF6),
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
            ..._appointments.map((appt) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryTealLight,
                    child: Text(
                      appt['name']!.substring(0, 1),
                      style: const TextStyle(
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(
                    appt['name']!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text('${appt['time']} · ${appt['reason']}'),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.iconGray,
                  ),
                  onTap: () =>
                      Navigator.of(context).pushNamed('/patient-details'),
                ),
              );
            }),
          ],
        ),
      floatingActionButton: const AppAddFab(routeName: '/add-appointment'),
      floatingActionButtonLocation: const AppFabAboveNavLocation(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}
