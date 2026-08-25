import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _infoTile(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryTeal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AppScaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 48,
                  backgroundImage: AssetImage('assets/doctor.png'),
                ),
                const SizedBox(height: 14),
                Text(auth.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
                const SizedBox(height: 2),
                Text(auth.specialty, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _infoTile(context, icon: Icons.badge_outlined, label: 'License Number', value: auth.licenseNumber),
                  const Divider(),
                  _infoTile(context, icon: Icons.email_outlined, label: 'Email', value: auth.email),
                  const Divider(),
                  _infoTile(context, icon: Icons.phone_outlined, label: 'Phone', value: auth.phone),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/edit-profile');
            },
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }
}