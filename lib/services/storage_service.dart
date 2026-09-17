import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Thrown by [StorageService] with a user-presentable message.
class StorageFailure implements Exception {
  final String message;
  const StorageFailure(this.message);

  @override
  String toString() => message;
}

/// Step 16: Supabase Storage access (avatars + patient attachments).
/// Path conventions (enforced by `supabase/storage.sql` RLS):
/// - avatars: `avatars/{uid}/avatar.jpg` (public read)
/// - attachments: `attachments/{uid}/{patientId}/{filename}` (private)
class StorageService {
  static const avatarsBucket = 'avatars';
  static const attachmentsBucket = 'attachments';

  static bool get useBackend => SupabaseConfig.isConfigured;

  static String? get _userId => useBackend
      ? SupabaseConfig.client.auth.currentUser?.id
      : null;

  static void _requireAuth() {
    if (_userId == null) {
      throw const StorageFailure('Please sign in again.');
    }
  }

  // ---------- Avatars ----------

  static String _avatarPath(String uid) => '$uid/avatar.jpg';

  /// Uploads [bytes] as the signed-in doctor's avatar and returns its
  /// public URL (the `avatars` bucket is public-read).
  static Future<String> uploadAvatar(
    Uint8List bytes, {
    String contentType = 'image/jpeg',
  }) async {
    _requireAuth();
    try {
      final path = _avatarPath(_userId!);
      await SupabaseConfig.client.storage.from(avatarsBucket).uploadBinary(
            path,
            bytes,
            fileOptions:
                FileOptions(contentType: contentType, upsert: true),
          );
      return SupabaseConfig.client.storage
          .from(avatarsBucket)
          .getPublicUrl(path);
    } catch (_) {
      throw const StorageFailure(
          'Could not upload photo. Check connection and try again.');
    }
  }

  // ---------- Attachments ----------

  static String _attachmentPrefix(String uid, String patientId) =>
      '$uid/$patientId';

  static String _attachmentPath(
          String uid, String patientId, String fileName) =>
      '${_attachmentPrefix(uid, patientId)}/$fileName';

  static String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[^\w.\-]+'), '_');

  /// Lists file names stored for [patientId] (remote uuid only;
  /// legacy local ids have no cloud folder).
  static Future<List<String>> listAttachments(String patientId) async {
    _requireAuth();
    if (!_isUuid(patientId)) return [];
    try {
      final objects = await SupabaseConfig.client.storage
          .from(attachmentsBucket)
          .list(path: _attachmentPrefix(_userId!, patientId));
      return objects
          .where((o) => o.name.isNotEmpty && o.name != '.emptyFolderPlaceholder')
          .map((o) => o.name)
          .toList();
    } catch (_) {
      throw const StorageFailure(
          'Could not load attachments. Check connection and try again.');
    }
  }

  /// Uploads [bytes] as an attachment for [patientId] and returns the
  /// stored file name (timestamped to avoid collisions).
  static Future<String> uploadAttachment({
    required String patientId,
    required String fileName,
    required Uint8List bytes,
    String contentType = 'application/octet-stream',
  }) async {
    _requireAuth();
    if (!_isUuid(patientId)) {
      throw const StorageFailure(
          'Attachments need a synced patient record. Re-add the patient while online.');
    }
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final stored = '${stamp}_${_sanitize(fileName)}';
      await SupabaseConfig.client.storage.from(attachmentsBucket).uploadBinary(
            _attachmentPath(_userId!, patientId, stored),
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );
      return stored;
    } catch (_) {
      throw const StorageFailure(
          'Could not upload file. Check connection and try again.');
    }
  }

  /// Returns a 1-hour signed URL for opening/downloading [fileName].
  static Future<String> attachmentUrl(
      String patientId, String fileName) async {
    _requireAuth();
    try {
      return await SupabaseConfig.client.storage
          .from(attachmentsBucket)
          .createSignedUrl(
            _attachmentPath(_userId!, patientId, fileName),
            3600,
          );
    } catch (_) {
      throw const StorageFailure(
          'Could not open file. Check connection and try again.');
    }
  }

  static Future<void> deleteAttachment(
      String patientId, String fileName) async {
    _requireAuth();
    try {
      await SupabaseConfig.client.storage.from(attachmentsBucket).remove(
        [_attachmentPath(_userId!, patientId, fileName)],
      );
    } catch (_) {
      throw const StorageFailure(
          'Could not delete file. Check connection and try again.');
    }
  }

  static bool _isUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}
