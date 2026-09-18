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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 17: global crash capture — framework errors + uncaught async
  // errors land in AppLogger (and persist the latest for Diagnostics).
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
        '/dashboard': (context) => const DashboardScreen(),
        '/patient-home': (context) => const PatientHomeScreen(),
        '/patient-book': (context) => const PatientBookScreen(),
        '/patient-prescriptions': (context) =>
            const PatientPrescriptionsScreen(),
        '/patient-reminders': (context) => const PatientRemindersScreen(),
        '/add-patient': (context) => const AddPatientScreen(),
        '/patient-list': (context) => const PatientListScreen(),
        '/add-appointment': (context) => const AddAppointmentScreen(),
        '/appointments': (context) => const AppointmentsScreen(),
        '/add-prescription': (context) => const AddPrescriptionScreen(),
        '/follow-up': (context) => const FollowUpScreen(),
        '/follow-ups': (context) => const FollowUpListScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/more': (context) => const MoreScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/patient-details': (context) => const PatientDetailsScreen(),
        '/medicine-list': (context) => const MedicineListScreen(),
        '/order-medicine': (context) => const OrderMedicineScreen(),
      },
    );
  }
}