import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/supabase_config.dart';
import '../utils/app_colors.dart';
import '../utils/app_env.dart';
import '../utils/app_logger.dart';
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language_outlined, color: AppColors.primaryTeal),
                    title: const Text('Language', style: TextStyle(fontSize: 15, fontWeight: FontWeight(600)),),
                    subtitle: const Text('Select Language'),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: settings.language,
                        items: const [
                          DropdownMenuItem(value: 'English', child: Text('English')),
                          DropdownMenuItem(value: 'Bangla', child: Text('বাংলা')),
                          DropdownMenuItem(value: 'Hindi', child: Text('हिन्दी')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            context.read<SettingsProvider>().setLanguage(value);
                          }
                        },
                      ),
                    ),
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

          _sectionHeader(context, 'DIAGNOSTICS'),
          const _DiagnosticsCard(),
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

/// Step 17: environment, backend mode and last recorded error.
class _DiagnosticsCard extends StatefulWidget {
  const _DiagnosticsCard();

  @override
  State<_DiagnosticsCard> createState() => _DiagnosticsCardState();
}

class _DiagnosticsCardState extends State<_DiagnosticsCard> {
  late Future<({String message, String at})?> _lastError;

  @override
  void initState() {
    super.initState();
    _lastError = AppLogger.lastError();
  }

  Future<void> _clear() async {
    await AppLogger.clearLastError();
    if (!mounted) return;
    setState(() => _lastError = AppLogger.lastError());
  }

  @override
  Widget build(BuildContext context) {
    final backend = SupabaseConfig.isConfigured
        ? 'Supabase (${AppEnv.current})'
        : 'Local mode';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dns_outlined,
                  color: AppColors.primaryTeal),
              title: const Text('Environment'),
              trailing: Text(
                backend,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Divider(),
            FutureBuilder<({String message, String at})?>(
              future: _lastError,
              builder: (context, snapshot) {
                final last = snapshot.data;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    last == null
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: last == null
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                  ),
                  title: const Text('Last error'),
                  subtitle: Text(
                    last == null
                        ? 'No errors recorded'
                        : last.at.isEmpty
                            ? last.message
                            : '${last.message}\n${last.at}',
                  ),
                  trailing: last == null
                      ? null
                      : TextButton(
                          onPressed: _clear,
                          child: const Text('Clear'),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}