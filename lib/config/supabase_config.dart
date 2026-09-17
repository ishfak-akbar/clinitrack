import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_env.dart';
import '../utils/app_logger.dart';

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
    // Step 17: env-specific file first (`.env.dev` / `.env.prod`),
    // then plain `.env`, then `--dart-define` (see [url]/[anonKey]).
    var loadedFrom = '';
    try {
      await dotenv.load(fileName: AppEnv.envFile);
      loadedFrom = AppEnv.envFile;
    } catch (_) {
      try {
        await dotenv.load(fileName: '.env');
        loadedFrom = '.env';
      } catch (_) {
        // No env file on first clone / CI - fall back to --dart-define.
      }
    }
    if (loadedFrom.isNotEmpty) {
      AppLogger.debug('Env loaded from $loadedFrom', tag: 'Supabase');
    }

    if (!isConfigured) {
      AppLogger.warning(
        'Supabase not configured (env=${AppEnv.current}) — '
        'running in local mode',
        tag: 'Supabase',
      );
      return; // Stay on local SharedPreferences mode.
    }

    // ignore: deprecated_member_use
    await Supabase.initialize(url: url, anonKey: anonKey);
    AppLogger.info(
      'Supabase connected (env=${AppEnv.current})',
      tag: 'Supabase',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
