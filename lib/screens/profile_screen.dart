import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/follow_up_provider.dart';
import '../widgets/user_avatar.dart';
import '../utils/app_colors.dart';

/// Tappable per-user avatar — gallery/camera pick, Supabase upload when
/// configured, otherwise local file path cached per account.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return UserAvatar(
      avatarUrl: auth.avatarUrl,
      name: auth.name,
      radius: 48,
      editable: true,
      onTap: () => pickAndSaveAvatar(context),
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
                if (!isPatient) ...[
                  const SizedBox(height: 8),
                  _VerificationBadge(
                    status: auth.verificationStatus,
                    isAdmin: auth.isAdmin,
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
                  if (auth.title.isNotEmpty) ...[
                    _infoTile(
                      context,
                      icon: Icons.assignment_ind_outlined,
                      label: 'Title',
                      value: auth.title,
                    ),
                    const Divider(),
                  ],
                  if (auth.degree.isNotEmpty) ...[
                    _infoTile(
                      context,
                      icon: Icons.workspace_premium_outlined,
                      label: 'Degree',
                      value: auth.degree,
                    ),
                    const Divider(),
                  ],
                  if (auth.graduatingInstitution.isNotEmpty ||
                      auth.graduationYear.isNotEmpty) ...[
                    _infoTile(
                      context,
                      icon: Icons.account_balance_outlined,
                      label: 'Graduated from',
                      value: auth.graduationYear.isEmpty
                          ? auth.graduatingInstitution
                          : '${auth.graduatingInstitution} · ${auth.graduationYear}',
                    ),
                    const Divider(),
                  ],
                  if (auth.specialties.isNotEmpty ||
                      auth.specialty.isNotEmpty) ...[
                    _infoTile(
                      context,
                      icon: Icons.medical_services_outlined,
                      label: 'Specialties',
                      value: auth.specialties.isNotEmpty
                          ? auth.specialties.join(', ')
                          : auth.specialty,
                    ),
                    const Divider(),
                  ],
                  if (auth.chamberName.isNotEmpty) ...[
                    _infoTile(
                      context,
                      icon: Icons.business_outlined,
                      label: 'Chamber',
                      value: auth.chamberName,
                    ),
                    const Divider(),
                  ],
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

/// Verification pill under the profile header (doctors only).
class _VerificationBadge extends StatelessWidget {
  final String status;
  final bool isAdmin;

  const _VerificationBadge({required this.status, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String label;
    final Color color;
    if (isAdmin) {
      icon = Icons.verified_user_outlined;
      label = 'Administrator';
      color = Theme.of(context).brightness == Brightness.dark
          ? AppColors.primaryTealAccent
          : AppColors.primaryTeal;
    } else if (status == 'approved') {
      icon = Icons.check_circle;
      label = 'Verified doctor';
      color = AppColors.successGreen;
    } else if (status == 'rejected') {
      icon = Icons.cancel_outlined;
      label = 'Verification rejected';
      color = AppColors.errorRed;
    } else {
      icon = Icons.hourglass_top_rounded;
      label = 'Verification pending';
      color = AppColors.warningAmber;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}