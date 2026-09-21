import 'package:flutter/material.dart';

import '../repositories/auth_repository.dart';
import '../utils/app_colors.dart';
import 'user_avatar.dart';

/// Rich doctor profile card for patients: gradient image banner,
/// per-doctor avatar, specialty chip, qualifications/experience/clinic,
/// with select + view-profile actions.
class DoctorCard extends StatelessWidget {
  final DoctorDirectoryEntry doctor;
  final bool selected;
  final VoidCallback? onSelect;
  final VoidCallback? onViewProfile;

  const DoctorCard({
    super.key,
    required this.doctor,
    this.selected = false,
    this.onSelect,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? accent : Colors.transparent,
          width: selected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Banner ----------
            Container(
              height: 84,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0E7C7B), const Color(0xFF1A3A38)]
                      : [const Color(0xFF0E7C7B), const Color(0xFF34C5C3)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 24,
                    top: -32,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 16,
                    bottom: 12,
                    child: Icon(
                      Icons.medical_services_outlined,
                      color: Colors.white70,
                      size: 26,
                    ),
                  ),
                  if (selected)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                size: 14, color: accent),
                            const SizedBox(width: 4),
                            Text(
                              'Selected',
                              style: TextStyle(
                                color: accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ---------- Body ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: UserAvatar(
                            avatarUrl: doctor.avatarUrl,
                            name: doctor.name,
                            radius: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor.name.isEmpty
                                      ? 'Doctor'
                                      : doctor.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (doctor.title.isNotEmpty)
                                  Text(
                                    doctor.title,
                                    style: theme.textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (doctor.specialty.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(
                                          alpha: isDark ? 0.18 : 0.10),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      doctor.specialty,
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (doctor.qualifications.isNotEmpty ||
                      doctor.experienceYears.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium_outlined, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            [
                              doctor.qualifications,
                              doctor.experienceYears.isEmpty
                                  ? ''
                                  : '${doctor.experienceYears} yrs exp'
                            ].where((e) => e.isNotEmpty).join(' · '),
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (doctor.chamberName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.business_outlined, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            doctor.chamberName,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (doctor.clinicAddress.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            doctor.clinicAddress,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (doctor.bio.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      doctor.bio,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onViewProfile,
                          child: const Text('View profile'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onSelect,
                          child:
                              Text(selected ? 'Selected' : 'Book'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full profile sheet shown when a patient taps View profile.
void showDoctorProfileSheet(
    BuildContext context, DoctorDirectoryEntry doctor) {
  final theme = Theme.of(context);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: UserAvatar(
              avatarUrl: doctor.avatarUrl,
              name: doctor.name,
              radius: 44,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              doctor.name.isEmpty ? 'Doctor' : doctor.name,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
          if (doctor.specialty.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  doctor.specialty,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (doctor.title.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.assignment_ind_outlined),
              title: const Text('Title'),
              subtitle: Text(doctor.title),
            ),
          if (doctor.degree.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Degree'),
              subtitle: Text(doctor.degree),
            ),
          if (doctor.graduatingInstitution.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_balance_outlined),
              title: const Text('Graduated from'),
              subtitle: Text(
                doctor.graduationYear.isEmpty
                    ? doctor.graduatingInstitution
                    : '${doctor.graduatingInstitution} · ${doctor.graduationYear}',
              ),
            ),
          if (doctor.specialtyLine.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.medical_services_outlined),
              title: const Text('Specialties'),
              subtitle: Text(doctor.specialtyLine),
            ),
          if (doctor.qualifications.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.school_outlined),
              title: const Text('Qualifications'),
              subtitle: Text(doctor.qualifications),
            ),
          if (doctor.experienceYears.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.work_history_outlined),
              title: const Text('Experience'),
              subtitle: Text('${doctor.experienceYears} years'),
            ),
          if (doctor.clinicAddress.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.local_hospital_outlined),
              title: const Text('Clinic'),
              subtitle: Text(doctor.clinicAddress),
            ),
          if (doctor.bio.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              subtitle: Text(doctor.bio),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(sheetContext).pop();
            },
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Choose this doctor below to book'),
          ),
        ],
      ),
    ),
  );
}

/// Compact selectable row for step flows (e.g. Book visit step 1):
/// avatar + name/specialty, radio indicator, chevron to view profile.
class DoctorSelectTile extends StatelessWidget {
  final DoctorDirectoryEntry doctor;
  final bool selected;
  final VoidCallback? onSelect;
  final VoidCallback? onViewProfile;

  const DoctorSelectTile({
    super.key,
    required this.doctor,
    this.selected = false,
    this.onSelect,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent =
        isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? accent : Colors.transparent,
          width: selected ? 2 : 0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              UserAvatar(
                avatarUrl: doctor.avatarUrl,
                name: doctor.name,
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name.isEmpty ? 'Doctor' : doctor.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        doctor.title,
                        doctor.specialty,
                        doctor.experienceYears.isEmpty
                            ? ''
                            : '${doctor.experienceYears} yrs exp',
                      ].where((e) => e.isNotEmpty).join(' · '),
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? accent : theme.disabledColor,
              ),
              IconButton(
                tooltip: 'View profile',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right),
                onPressed: onViewProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
