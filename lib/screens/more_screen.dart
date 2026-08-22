import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/more_menu_tile.dart';

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
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.screenTintedBackground,
      appBar: AppBar(
        backgroundColor: AppColors.screenTintedBackground,
        automaticallyImplyLeading: false,
        title: const Text('More'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- Profile summary ----------
          Card(
            child: ListTile(
              onTap: () => Navigator.of(context).pushNamed('/profile'),
              contentPadding: const EdgeInsets.all(12),
              leading: const CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryTealLight,
                child: Icon(Icons.person, color: AppColors.primaryTeal, size: 28),
              ),
              title: Text('Dr. Sarah Ahmed', style: Theme.of(context).textTheme.titleMedium),
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