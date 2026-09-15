import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static String get url =>
      const String.fromEnvironment('SUPABASE_URL',
          defaultValue: '') .isNotEmpty
          ? const String.fromEnvironment('SUPABASE_URL')
          : dotenv.env['SUPABASE_URL'] ?? '';

  static String get anonKey =>
      const String.fromEnvironment('SUPABASE_ANON_KEY',
          defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('SUPABASE_ANON_KEY')
          : dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static bool get isConfigured =>
      url.isNotEmpty && anonKey.isNotEmpty && !url.contains('xyzcompany');

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env missing on first clone - fall back to --dart-define.
    }

    if (!isConfigured) return; // Stay on local SharedPreferences mode.

    // ignore: deprecated_member_use
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
