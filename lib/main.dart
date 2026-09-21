import 'dart:async';

import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/prescription_provider.dart';
import 'providers/medicine_provider.dart';
import 'providers/follow_up_provider.dart';
import 'providers/stats_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/app_env.dart';
import 'utils/app_logger.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/patient_home_screen.dart';
import 'screens/patient_book_screen.dart';
import 'screens/patient_edit_screen.dart';
import 'screens/patient_prescriptions_screen.dart';
import 'screens/patient_reminders_screen.dart';
import 'screens/add_patient_screen.dart';
import 'screens/patient_list_screen.dart';
import 'screens/patient_details_screen.dart';
import 'screens/add_appointment_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/add_prescription_screen.dart';
import 'screens/follow_up_screen.dart';
import 'screens/follow_up_list_screen.dart';
import 'screens/more_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/medicine_list_screen.dart';
import 'screens/order_medicine_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/doctor_application_screen.dart';
import 'screens/verification_pending_screen.dart';
import 'screens/admin_screen.dart';
import 'widgets/role_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global crash capture — framework errors + uncaught async errors land
  // in AppLogger (latest error surfaced under Settings > Diagnostics).
  FlutterError.onError = (details) {
    AppLogger.error(
      'Flutter framework error',
      tag: 'Flutter',
      error: details.exception,
      stack: details.stack,
    );
  };

  runZonedGuarded(
    () async {
      await SupabaseConfig.init();
      AppLogger.info(
        'CliniTrack starting (env=${AppEnv.current})',
        tag: 'App',
      );
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => PatientProvider()),
            ChangeNotifierProvider(create: (_) => AppointmentProvider()),
            ChangeNotifierProvider(create: (_) => PrescriptionProvider()),
            ChangeNotifierProvider(create: (_) => MedicineProvider()),
            ChangeNotifierProvider(create: (_) => FollowUpProvider()),
            ChangeNotifierProvider(create: (_) => StatsProvider()),
          ],
          child: const CliniTrackApp(),
        ),
      );
    },
    (error, stack) {
      AppLogger.error(
        'Uncaught async error',
        tag: 'App',
        error: error,
        stack: stack,
      );
    },
  );
}

class CliniTrackApp extends StatelessWidget {
  const CliniTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = context.watch<SettingsProvider>().darkMode;

    return MaterialApp(
      title: 'CliniTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/doctor-apply': (context) => const RoleGuard(
            doctorOnly: true, child: DoctorApplicationScreen()),
        // Unguarded on purpose: the screen handles logged-out users itself,
        // and the gate above confines unapproved doctors to it.
        '/verification-pending': (context) =>
            const VerificationPendingScreen(),
        '/admin': (context) =>
            const RoleGuard(adminOnly: true, child: AdminScreen()),
        '/dashboard': (context) =>
            const RoleGuard(doctorOnly: true, child: DashboardScreen()),
        '/patient-home': (context) =>
            const RoleGuard(patientOnly: true, child: PatientHomeScreen()),
        '/patient-book': (context) =>
            const RoleGuard(patientOnly: true, child: PatientBookScreen()),
        '/patient-edit': (context) =>
            const RoleGuard(patientOnly: true, child: PatientEditScreen()),
        '/patient-prescriptions': (context) => const RoleGuard(
            patientOnly: true, child: PatientPrescriptionsScreen()),
        '/patient-reminders': (context) => const RoleGuard(
            patientOnly: true, child: PatientRemindersScreen()),
        '/add-patient': (context) =>
            const RoleGuard(doctorOnly: true, child: AddPatientScreen()),
        '/patient-list': (context) =>
            const RoleGuard(doctorOnly: true, child: PatientListScreen()),
        '/add-appointment': (context) =>
            const RoleGuard(doctorOnly: true, child: AddAppointmentScreen()),
        '/appointments': (context) =>
            const RoleGuard(doctorOnly: true, child: AppointmentsScreen()),
        '/add-prescription': (context) => const RoleGuard(
            doctorOnly: true, child: AddPrescriptionScreen()),
        '/follow-up': (context) =>
            const RoleGuard(doctorOnly: true, child: FollowUpScreen()),
        '/follow-ups': (context) =>
            const RoleGuard(doctorOnly: true, child: FollowUpListScreen()),
        '/reports': (context) =>
            const RoleGuard(doctorOnly: true, child: ReportsScreen()),
        '/more': (context) =>
            const RoleGuard(doctorOnly: true, child: MoreScreen()),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit-profile': (context) =>
            const RoleGuard(doctorOnly: true, child: EditProfileScreen()),
        '/patient-details': (context) =>
            const RoleGuard(doctorOnly: true, child: PatientDetailsScreen()),
        '/medicine-list': (context) =>
            const RoleGuard(doctorOnly: true, child: MedicineListScreen()),
        '/order-medicine': (context) =>
            const RoleGuard(doctorOnly: true, child: OrderMedicineScreen()),
      },
    );
  }
}