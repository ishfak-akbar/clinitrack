import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Step 17: lightweight app-wide logging + last-crash persistence.
///
/// - `debug`/`info` print in debug builds only.
/// - `warning`/`error` always print (visible in release device logs too).
/// - `error` also persists a summary to SharedPreferences so the most
///   recent crash survives restarts (see Settings > Diagnostics).
/// This is intentionally dependency-free; swap the sinks for Crashlytics
/// later without touching call sites.
class AppLogger {
  static const String _keyLastError = 'diagnostics_last_error';
  static const String _keyLastErrorAt = 'diagnostics_last_error_at';
  static const int _bufferSize = 100;

  static final List<String> _buffer = [];

  /// Most recent log lines, newest last (in-memory, per session).
  static List<String> get recent => List.unmodifiable(_buffer);

  static void debug(String message, {String tag = 'App'}) {
    if (kDebugMode) _write('DEBUG', tag, message);
  }

  static void info(String message, {String tag = 'App'}) {
    if (kDebugMode) _write('INFO', tag, message);
  }

  static void warning(String message, {String tag = 'App'}) {
    _write('WARN', tag, message);
  }

  static void error(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stack,
  }) {
    _write('ERROR', tag, message);
    if (error != null) _write('ERROR', tag, '$error');
    if (stack != null && kDebugMode) _write('ERROR', tag, '$stack');
    unawaited(_persist(message));
  }

  static void _write(String level, String tag, String message) {
    final line =
        '[${DateTime.now().toIso8601String()}][$level][$tag] $message';
    _buffer.add(line);
    if (_buffer.length > _bufferSize) _buffer.removeAt(0);
    // ignore: avoid_print
    print(line);
  }

  static Future<void> _persist(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastError, message);
      await prefs.setString(
          _keyLastErrorAt, DateTime.now().toIso8601String());
    } catch (_) {
      // Diagnostics must never crash the app.
    }
  }

  static Future<({String message, String at})?> lastError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final message = prefs.getString(_keyLastError);
      if (message == null || message.isEmpty) return null;
      return (
        message: message,
        at: prefs.getString(_keyLastErrorAt) ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearLastError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastError);
      await prefs.remove(_keyLastErrorAt);
    } catch (_) {
      // Best effort only.
    }
  }
}
