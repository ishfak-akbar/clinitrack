import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';

/// Single source of truth for profile pictures.
///
/// - Supabase URL (`http...`) → network image (per-user `avatar_url`).
/// - Local file path (offline mode) → file image, stored per-account in
///   SharedPreferences via [AuthProvider.avatarUrl].
/// - Empty/invalid → initials circle derived from [name] so every profile
///   looks owned, never the same stock `doctor.png` for everyone.
class UserAvatar extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final double radius;
  final bool editable;
  final bool uploading;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.radius = 24,
    this.editable = false,
    this.uploading = false,
    this.onTap,
  });

  String _initials() {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  Widget _fallback(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.primaryTealAccent, const Color(0xFF0E7C7B)]
              : [const Color(0xFF14A8A6), AppColors.primaryTeal],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.75,
          ),
        ),
      ),
    );
  }

  Widget _image(BuildContext context) {
    final url = avatarUrl.trim();
    if (url.isEmpty) return _fallback(context);
    if (url.startsWith('http')) {
      return ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(context),
          ),
        ),
      );
    }
    // Local-mode file path (mobile/desktop only).
    if (!kIsWeb) {
      try {
        final file = File(url);
        if (file.existsSync()) {
          return ClipOval(
            child: SizedBox(
              width: radius * 2,
              height: radius * 2,
              child: Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(context),
              ),
            ),
          );
        }
      } catch (_) {
        // Fall through to initials.
      }
    }
    return _fallback(context);
  }

  @override
  Widget build(BuildContext context) {
    final avatar = Stack(
      children: [
        _image(context),
        if (uploading)
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        else if (editable)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );

    if (onTap == null && !editable) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}

/// Picks a profile photo and saves it per-user:
/// backend → Supabase Storage `avatars/{uid}/avatar.jpg`,
/// offline → local file path cached in SharedPreferences.
Future<void> pickAndSaveAvatar(BuildContext context) async {
  final sheet = await showModalBottomSheet<ImageSource?>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (sheet == null || !context.mounted) return;

  final file = await ImagePicker().pickImage(
    source: sheet,
    maxWidth: 512,
    imageQuality: 80,
  );
  if (file == null || !context.mounted) return;

  final auth = context.read<AuthProvider>();
  final messenger = ScaffoldMessenger.of(context);

  // Offline / local mode: keep the file path per account.
  if (!StorageService.useBackend) {
    if (kIsWeb) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Photo upload needs Supabase configured on web.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final ok = await auth.updateAvatarUrl(file.path);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Profile photo updated' : 'Could not save photo'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  try {
    final bytes = await file.readAsBytes();
    final url = await StorageService.uploadAvatar(bytes);
    if (!context.mounted) return;
    final ok = await context.read<AuthProvider>().updateAvatarUrl(url);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Profile photo updated'
            : context.read<AuthProvider>().errorMessage.isEmpty
                ? 'Photo uploaded, profile sync failed.'
                : context.read<AuthProvider>().errorMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } on StorageFailure catch (e) {
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}
