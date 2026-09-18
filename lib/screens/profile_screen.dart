import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/follow_up_provider.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';

/// Step 16: tappable avatar — gallery/camera pick, Storage upload,
/// URL persisted to `profiles.avatar_url`.
class _ProfileAvatar extends StatefulWidget {
  const _ProfileAvatar();

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  bool _uploading = false;

  Widget _image(String url) {
    if (url.isEmpty) {
      return Image.asset('assets/doctor.png', fit: BoxFit.cover);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Image.asset('assets/doctor.png', fit: BoxFit.cover),
    );
  }

  Future<void> _pick(ImageSource source) async {
    if (!StorageService.useBackend) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo upload needs Supabase configured.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 512,
      imageQuality: 80,
    );
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final url = await StorageService.uploadAvatar(bytes);
      if (!mounted) return;
      final ok = await context.read<AuthProvider>().updateAvatarUrl(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pick(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = context.watch<AuthProvider>().avatarUrl;

    return GestureDetector(
      onTap: _uploading ? null : _showSourceSheet,
      child: Stack(
        children: [
          ClipOval(
            child: SizedBox(
              width: 96,
              height: 96,
              child: _image(url),
            ),
          ),
          if (_uploading)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          else
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
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _infoTile(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Icon(
              icon,
              color: AppColors.primaryTeal,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      BuildContext context, {
        required IconData icon,
        required String value,
        required String label,
        required Color color,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 7),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Widget child,
      }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: AppColors.primaryTeal,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isPatient = auth.isPatient;
    final totalPatients =
        context.watch<PatientProvider>().patients.length;
    final totalAppointments =
        context.watch<AppointmentProvider>().appointments.length;
    final totalPrescriptions =
        context.watch<PrescriptionProvider>().prescriptions.length;
    final totalReminders =
        context.watch<FollowUpProvider>().followUps.length;

    return AppScaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- Profile header ----------
          Center(
            child: Column(
              children: [
                const _ProfileAvatar(),
                const SizedBox(height: 14),
                Text(
                  auth.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 2),
                Text(
                  isPatient ? 'Patient' : auth.specialty,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (auth.memberSince.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Member since ${auth.memberSince}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ---------- Activity stats ----------
          Row(
            children: [
              _statCard(
                context,
                icon: isPatient
                    ? Icons.calendar_month_outlined
                    : Icons.groups_outlined,
                value: isPatient
                    ? '$totalAppointments'
                    : '$totalPatients',
                label: isPatient ? 'My visits' : 'Patients',
                color: AppColors.successGreen,
              ),
              const SizedBox(width: 7),
              _statCard(
                context,
                icon: isPatient
                    ? Icons.medication_outlined
                    : Icons.calendar_month_outlined,
                value: isPatient
                    ? '$totalPrescriptions'
                    : '$totalAppointments',
                label: isPatient ? 'Prescriptions' : 'Appointments',
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 7),
              _statCard(
                context,
                icon: isPatient
                    ? Icons.event_available_outlined
                    : Icons.medication_outlined,
                value: isPatient
                    ? '$totalReminders'
                    : '$totalPrescriptions',
                label: isPatient ? 'Reminders' : 'Prescriptions',
                color: AppColors.followUpOrange,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ---------- About ----------
          if (auth.bio.isNotEmpty) ...[
            _sectionCard(
              context,
              title: 'About',
              icon: Icons.account_circle_outlined,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  auth.bio,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 7),
          ],

          // ---------- Professional details (doctors only) ----------
          if (!isPatient) ...[
            _sectionCard(
              context,
              title: 'Professional Details',
              icon: Icons.workspace_premium_outlined,
              child: Column(
                children: [
                  _infoTile(
                    context,
                    icon: Icons.menu_book_outlined,
                    label: 'Qualifications',
                    value: auth.qualifications,
                  ),
                  const Divider(),
                  _infoTile(
                    context,
                    icon: Icons.timeline_outlined,
                    label: 'Experience',
                    value: '${auth.experienceYears} years',
                  ),
                  const Divider(),
                  _infoTile(
                    context,
                    icon: Icons.local_hospital_outlined,
                    label: 'Clinic Address',
                    value: auth.clinicAddress,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
          ],

          // ---------- Account information ----------
          _sectionCard(
            context,
            title: 'Account Information',
            icon: Icons.manage_accounts_outlined,
            child: Column(
              children: [
                if (!isPatient) ...[
                  _infoTile(
                    context,
                    icon: Icons.verified_user_outlined,
                    label: 'License Number',
                    value: auth.licenseNumber,
                  ),
                  const Divider(),
                ],
                _infoTile(
                  context,
                  icon: Icons.alternate_email_outlined,
                  label: 'Email',
                  value: auth.email,
                ),
                const Divider(),
                _infoTile(
                  context,
                  icon: Icons.phone_android_outlined,
                  label: 'Phone',
                  value: auth.phone,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          if (isPatient)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/patient-edit');
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit health profile'),
            ),
          if (!isPatient)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/edit-profile');
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile'),
            ),
        ],
      ),
    );
  }
}