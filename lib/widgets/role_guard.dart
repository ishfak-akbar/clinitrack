import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Part 5: role-based route guard — patients stay on portal routes,
/// doctors stay on clinic routes. Shared routes: splash/login/register,
/// profile/settings.
class RoleGuard extends StatelessWidget {
  final Widget child;
  final bool doctorOnly;
  final bool patientOnly;

  const RoleGuard({
    super.key,
    required this.child,
    this.doctorOnly = false,
    this.patientOnly = false,
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
