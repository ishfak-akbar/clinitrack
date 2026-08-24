import 'package:flutter/material.dart';
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
    return Scaffold(
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
                  backgroundColor: AppColors.primaryTealLight,
                  child: Icon(Icons.person, size: 52, color: AppColors.primaryTeal),
                ),
                const SizedBox(height: 14),
                Text('Dr. Sarah Ahmed', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
                const SizedBox(height: 2),
                Text('General Physician', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _infoTile(context, icon: Icons.badge_outlined, label: 'License Number', value: 'MBBS-214578'),
                  const Divider(),
                  _infoTile(context, icon: Icons.email_outlined, label: 'Email', value: 'sarah.ahmed@clinic.com'),
                  const Divider(),
                  _infoTile(context, icon: Icons.phone_outlined, label: 'Phone', value: '01912345678'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit Profile coming soon')),
              );
            },
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }
}