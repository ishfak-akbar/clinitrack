import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/follow_up_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/stats_provider.dart';
import '../utils/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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

  Widget _navTile(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String routeName,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isActive = currentRoute == routeName;

    return ListTile(
      leading: Icon(icon, color: isActive ? accent : AppColors.iconGray),
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: isActive ? accent : null,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: accent.withValues(alpha: isDark ? 0.12 : 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.of(context).pop();
        if (!isActive) {
          Navigator.of(context).pushNamed(routeName);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ---------- Header ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage('assets/doctor.png'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.specialty,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: accent.withValues(alpha: isDark ? 0.2 : 0.12)),

            // ---------- Nav items ----------
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _navTile(context, icon: Icons.dashboard_outlined, label: 'Dashboard', routeName: '/dashboard'),
                  _navTile(context, icon: Icons.people_outline, label: 'Patients', routeName: '/patient-list'),
                  _navTile(context, icon: Icons.event_note_outlined, label: 'Appointments', routeName: '/appointments'),
                  _navTile(context, icon: Icons.receipt_long_outlined, label: 'Add Prescription', routeName: '/add-prescription'),
                  _navTile(context, icon: Icons.schedule_outlined, label: 'Follow-up', routeName: '/follow-up'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _navTile(context, icon: Icons.bar_chart_outlined, label: 'Reports', routeName: '/reports'),
                  _navTile(context, icon: Icons.medication_outlined, label: 'Medicine Inventory', routeName: '/medicine-list'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _navTile(context, icon: Icons.person_outline, label: 'Profile', routeName: '/profile'),
                  _navTile(context, icon: Icons.settings_outlined, label: 'Settings', routeName: '/settings'),
                ],
              ),
            ),

            // ---------- Logout ----------
            Divider(height: 1, color: accent.withValues(alpha: isDark ? 0.2 : 0.12)),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.errorRed),
              title: const Text('Logout', style: TextStyle(color: AppColors.errorRed)),
              onTap: () => _confirmLogout(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}