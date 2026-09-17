import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/more_menu_tile.dart';
import 'package:provider/provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/follow_up_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/stats_provider.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: AppColors.errorRed, size: 36),
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout of your session?',
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Read before the await — never let the next account glimpse
      // the previous one's data.
      final patients = context.read<PatientProvider>();
      final appointments = context.read<AppointmentProvider>();
      final prescriptions = context.read<PrescriptionProvider>();
      final medicines = context.read<MedicineProvider>();
      final followUps = context.read<FollowUpProvider>();
      final stats = context.read<StatsProvider>();
      await context.read<AuthProvider>().logout();
      patients.clearCache();
      appointments.clearCache();
      prescriptions.clearCache();
      medicines.clearCache();
      followUps.clearCache();
      stats.clearCache();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('More'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ---------- Profile summary ----------
          Card(
            child: ListTile(
              onTap: () => Navigator.of(context).pushNamed('/profile'),
              contentPadding: const EdgeInsets.all(12),
              leading: const CircleAvatar(
                radius: 26,
                backgroundImage: AssetImage('assets/doctor.png'),
              ),
              title: Text('Dr. Ishfak Akbar', style: Theme.of(context).textTheme.titleMedium),
              subtitle: const Text('General Physician'),
              trailing: const Icon(Icons.chevron_right, color: AppColors.iconGray),
            ),
          ),
          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  MoreMenuTile(
                    icon: Icons.bar_chart_outlined,
                    title: 'Reports',
                    subtitle: 'Clinic statistics & summaries',
                    onTap: () => Navigator.of(context).pushNamed('/reports'),
                  ),
                  const Divider(),
                  MoreMenuTile(
                    icon: Icons.medication_outlined,
                    title: 'Medicine Inventory',
                    subtitle: 'View stock & order medicines',
                    onTap: () => Navigator.of(context).pushNamed('/medicine-list'),
                  ),
                  const Divider(),
                  MoreMenuTile(
                    icon: Icons.event_available_outlined,
                    title: 'Follow-ups',
                    subtitle: 'Pending & completed reminders',
                    onTap: () => Navigator.of(context).pushNamed('/follow-ups'),
                  ),
                  const Divider(),
                  MoreMenuTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'Appearance, notifications & more',
                    onTap: () => Navigator.of(context).pushNamed('/settings'),
                  ),
                  const Divider(),
                  MoreMenuTile(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    subtitle: 'View & edit your information',
                    onTap: () => Navigator.of(context).pushNamed('/profile'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: MoreMenuTile(
                icon: Icons.logout_rounded,
                title: 'Logout',
                iconColor: AppColors.errorRed,
                titleColor: AppColors.errorRed,
                onTap: () => _confirmLogout(context),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}