import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Server-side clinic statistics for the signed-in doctor.
///
/// Every number comes from a `COUNT(*)` query (RLS scopes rows to
/// `owner_id = auth.uid()`), never from in-memory filtering.
class ClinicStats {
  final int totalPatients;
  final int totalAppointments;
  final int todayAppointments;
  final int totalPrescriptions;
  final int followUpsDue;
  final int lowStockMedicines;
  final Map<String, int> genderCounts; // Male / Female / Other
  final Map<String, int> bloodGroupCounts; // A+ .. AB-

  const ClinicStats({
    this.totalPatients = 0,
    this.totalAppointments = 0,
    this.todayAppointments = 0,
    this.totalPrescriptions = 0,
    this.followUpsDue = 0,
    this.lowStockMedicines = 0,
    this.genderCounts = const {},
    this.bloodGroupCounts = const {},
  });

  int get totalByGender =>
      genderCounts.values.fold(0, (sum, n) => sum + n);
}

class StatsService {
  static const lowStockThreshold = 40;

  static bool get useBackend => SupabaseConfig.isConfigured;

  static const bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-',
  ];

  static String todayIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// Runs all count queries in parallel and returns the combined stats.
  /// Throws on connection/auth failure (caller surfaces `errorMessage`).
  static Future<ClinicStats> fetchStats() async {
    final client = SupabaseConfig.client;
    final today = todayIso();

    final results = await Future.wait([
      client.from('patients').count(CountOption.exact),
      client.from('appointments').count(CountOption.exact),
      client.from('appointments').count().eq('date_iso', today),
      client.from('prescriptions').count(CountOption.exact),
      client.from('follow_ups').count().eq('is_done', false),
      client
          .from('medicines')
          .count()
          .lt('stock', lowStockThreshold),
      // Gender breakdown (3 parallel counts).
      client.from('patients').count().eq('gender', 'Male'),
      client.from('patients').count().eq('gender', 'Female'),
      client.from('patients').count().eq('gender', 'Other'),
      // Blood-group breakdown (8 parallel counts).
      for (final group in bloodGroups)
        client.from('patients').count().eq('blood_group', group),
    ]);

    return ClinicStats(
      totalPatients: results[0],
      totalAppointments: results[1],
      todayAppointments: results[2],
      totalPrescriptions: results[3],
      followUpsDue: results[4],
      lowStockMedicines: results[5],
      genderCounts: {
        'Male': results[6],
        'Female': results[7],
        'Other': results[8],
      },
      bloodGroupCounts: {
        for (var i = 0; i < bloodGroups.length; i++)
          bloodGroups[i]: results[9 + i],
      },
    );
  }
}
