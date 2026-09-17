import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Step 17: dev/prod environments.
///
/// Resolution order for the environment name:
/// 1. `--dart-define=APP_ENV=prod` (CI / release builds — required for prod
///    so no prod secrets ever live in a file),
/// 2. `APP_ENV` inside the loaded `.env` file,
/// 3. `'dev'` default.
///
/// `SupabaseConfig` loads `.env.<name>` first (e.g. `.env.dev`),
/// falling back to `.env`.
class AppEnv {
  static const String _defined =
      String.fromEnvironment('APP_ENV', defaultValue: '');

  static String get current {
    if (_defined.isNotEmpty) return _defined;
    return dotenv.env['APP_ENV'] ?? 'dev';
  }

  static bool get isProd => current == 'prod';

  static bool get isDev => !isProd;

  /// Env-specific dotenv file, e.g. `.env.dev` / `.env.prod`.
  static String get envFile => '.env.$current';
}
