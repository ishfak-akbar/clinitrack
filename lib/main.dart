import 'package:flutter/material.dart';
import 'utils/app_theme.dart';
import 'utils/app_colors.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_patient_screen.dart';
import 'screens/patient_list_screen.dart';
import 'screens/patient_details_screen.dart';
import 'screens/add_appointment_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/add_prescription_screen.dart';
import 'screens/follow_up_screen.dart';

void main() {
  runApp(const CliniTrackApp());
}

class CliniTrackApp extends StatelessWidget {
  const CliniTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CliniTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/add-patient': (context) => const AddPatientScreen(),
        '/patient-list': (context) => const PatientListScreen(),
        '/add-appointment': (context) => const AddAppointmentScreen(),
        '/appointments': (context) => const AppointmentsScreen(),
        '/add-prescription': (context) => const AddPrescriptionScreen(),
        '/follow-up': (context) => const FollowUpScreen(),
        '/more': (context) => const _DefaultPlaceholder(title: 'More'),
        '/profile': (context) => const _DefaultPlaceholder(title: 'Profile'),
        '/patient-details': (context) => const PatientDetailsScreen(),

      },
    );
  }
}

class _DefaultPlaceholder extends StatelessWidget {
  final String title;
  const _DefaultPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primaryTealLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.construction_rounded, size: 48, color: AppColors.primaryTeal),
              ),
              const SizedBox(height: 20),
              Text('$title — Coming Soon', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('This screen is under construction.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}