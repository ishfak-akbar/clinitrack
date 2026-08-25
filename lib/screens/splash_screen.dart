import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/medicine_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final patientProvider = context.read<PatientProvider>();
    final appointmentProvider = context.read<AppointmentProvider>();
    final prescriptionProvider = context.read<PrescriptionProvider>();

    await Future.wait([
      authProvider.loadSession(),
      settingsProvider.loadSettings(),
      patientProvider.loadPatients(),
      appointmentProvider.loadAppointments(),
      prescriptionProvider.loadPrescriptions(),
      context.read<MedicineProvider>().loadMedicines(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      authProvider.isLoggedIn ? '/dashboard' : '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              AppColors.darkBackground,
              AppColors.darkSurface,
              AppColors.darkCard.withValues(alpha: 0.9),
            ]
                : [
              const Color(0xFFE8F5F4),
              AppColors.screenTintedBackground,
              const Color(0xFFD6EFEC),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/cliniTrackIcon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text('CliniTrack', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Clinic Assistant',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primaryTeal),
                ),
                const SizedBox(height: 12),
                Text(
                  'Smart. Simple. Secure.\nBetter care, every day.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textGray),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: -10,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Center(
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: AppColors.cardWhite,
                          child: Icon(Icons.medical_services_rounded, size: 72, color: AppColors.primaryTeal),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}