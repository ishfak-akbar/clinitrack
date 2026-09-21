import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Part 5: role-based route guard — patients stay on portal routes,
/// doctors stay on clinic routes. Shared routes: splash/login/register,
/// profile/settings.
///
/// Step 3 (doctor verification, fully-blocked model): signed-in, non-admin,
/// non-patient accounts without approval are additionally confined to the
/// pending screen + application form — every other guarded route bounces.
///
/// Step 5: `adminOnly` routes (the review queue) bounce everyone else.
class RoleGuard extends StatelessWidget {
  final Widget child;
  final bool doctorOnly;
  final bool patientOnly;
  final bool adminOnly;

  const RoleGuard({
    super.key,
    required this.child,
    this.doctorOnly = false,
    this.patientOnly = false,
    this.adminOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Session still loading (splash covers initial load) — don't flicker.
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!auth.isLoggedIn) return child;

    if (adminOnly && !auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).pushReplacementNamed(auth.homeRoute);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (needsVerificationGate(
      role: auth.role,
      verificationStatus: auth.verificationStatus,
    )) {
      final routeName = ModalRoute.of(context)?.settings.name;
      if (routeName != '/verification-pending' &&
          routeName != '/doctor-apply') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          Navigator.of(context).pushReplacementNamed('/verification-pending');
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
    }

    final isPatient = auth.isPatient;
    final wrongSide =
        (doctorOnly && isPatient) || (patientOnly && !isPatient);
    if (!wrongSide) return child;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacementNamed(auth.homeRoute);
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
