import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/settings_provider.dart';
import '../widgets/more_menu_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return AppScaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(context, 'APPEARANCE'),
          Card(
            child: SwitchListTile(
              value: settings.darkMode,
              secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primaryTeal),
              title: const Text('Dark Mode'),
              onChanged: (value) => context.read<SettingsProvider>().setDarkMode(value),
            ),
          ),
          const SizedBox(height: 20),

          _sectionHeader(context, 'NOTIFICATIONS'),
          Card(
            child: SwitchListTile(
              value: settings.appointmentReminder,
              secondary: const Icon(Icons.notifications_outlined, color: AppColors.primaryTeal),
              title: const Text('Appointment Reminder'),
              onChanged: (value) => context.read<SettingsProvider>().setAppointmentReminder(value),
            ),
          ),
          const SizedBox(height: 20),

          _sectionHeader(context, 'GENERAL'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  MoreMenuTile(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: 'English',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Language options coming soon')),
                      );
                    },
                  ),
                  const Divider(),
                  MoreMenuTile(
                    icon: Icons.backup_outlined,
                    title: 'Data Backup',
                    subtitle: 'Backup & Restore',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Backup & Restore coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _sectionHeader(context, 'ABOUT'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: MoreMenuTile(
                icon: Icons.info_outline,
                title: 'About App',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CliniTrack v1.0.0')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}