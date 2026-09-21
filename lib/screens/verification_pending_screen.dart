import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

/// Step 3 (doctor verification, fully-blocked model): the waiting room for
/// unapproved doctors. Pending accounts see the under-review state;
/// rejected accounts see the admin's reason plus a resubmit path.
/// No clinical routes are reachable until approval (see [RoleGuard]).
class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  State<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState
    extends State<VerificationPendingScreen> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await context.read<AuthProvider>().loadSession();
    if (!mounted) return;
    setState(() => _refreshing = false);
    // Approved while waiting → leave the waiting room immediately.
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn && auth.verificationStatus == 'approved') {
      Navigator.of(context).pushReplacementNamed(auth.homeRoute);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent =
        isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

    if (!auth.isLoggedIn && !auth.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final rejected = auth.verificationStatus == 'rejected';
    final reason = auth.rejectionReason.trim();

    return AppScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Verification'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_outlined),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: (rejected ? AppColors.errorRed : accent)
                      .withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  rejected
                      ? Icons.assignment_late_outlined
                      : Icons.hourglass_top_rounded,
                  color: rejected ? AppColors.errorRed : accent,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              rejected ? 'Application needs attention' : 'Under review',
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              rejected
                  ? 'An admin reviewed your application and asked for changes. '
                      'Update your details and resubmit.'
                  : 'Your application is with our admins. You will get full '
                      'access as soon as it is approved.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (rejected && reason.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.errorRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reviewer note',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(reason, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/doctor-apply'),
              icon: const Icon(Icons.edit_outlined),
              label: Text(
                rejected ? 'Update and resubmit' : 'View my application',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _refreshing ? null : _refresh,
              icon: _refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_outlined),
              label: Text(
                _refreshing ? 'Checking…' : 'Check approval status',
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _logout,
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
