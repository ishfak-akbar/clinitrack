import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/follow_up_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/stats_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/list_states.dart';
import '../widgets/patient_bottom_nav.dart';
import '../widgets/status_chip.dart';

/// Part 5: patient portal home — read-only views of own bookings,
/// prescriptions and reminders, plus entry to booking and logout.
///
/// Sync contract: every list shown here comes from its provider, which reads
/// through RLS (`patient_id in my_patient_ids`), so a patient only ever sees
/// their own rows. This screen refreshes all four providers on entry and on
/// pull-to-refresh, and re-refreshes after returning from Book visit so a
/// just-sent request appears without a manual pull.
///
/// Sections for prescriptions / reminders render only when they have data
/// (or are loading / failed) — the dedicated tab screens own the empty
/// states, keeping this dashboard focused.
class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    final patients = context.read<PatientProvider>();
    await Future.wait([
      patients.loadPatients(),
      // Ensures the linked profile row exists locally; booking depends on it.
      patients.fetchMyLinked(),
      context.read<AppointmentProvider>().loadAppointments(),
      context.read<PrescriptionProvider>().loadPrescriptions(),
      context.read<FollowUpProvider>().loadFollowUps(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _bookVisit() async {
    await Navigator.of(context).pushNamed('/patient-book');
    if (!mounted) return;
    // A just-sent request should appear without a manual pull-to-refresh.
    await _refresh();
  }

  Future<void> _logout() async {
    final patients = context.read<PatientProvider>();
    final appointments = context.read<AppointmentProvider>();
    final prescriptions = context.read<PrescriptionProvider>();
    final medicines = context.read<MedicineProvider>();
    final followUps = context.read<FollowUpProvider>();
    final stats = context.read<StatsProvider>();
    await context.read<AuthProvider>().logout();
    patients.clearCache();
    appointments.clearCache();
    prescriptions.clearCache();
    medicines.clearCache();
    followUps.clearCache();
    stats.clearCache();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
  }

  Future<void> _cancel(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(
          '${appointment.date} · ${appointment.time}\n'
          'Your doctor will be notified. You can book another slot anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context
        .read<AppointmentProvider>()
        .updateStatus(appointment.id, 'cancelled');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Booking cancelled'
            : context.read<AppointmentProvider>().errorMessage.isEmpty
                ? 'Could not cancel booking'
                : context.read<AppointmentProvider>().errorMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Active bookings first (earliest first), then history (newest first).
  List<Appointment> _sortedAppointments(List<Appointment> all) {
    final sorted = List<Appointment>.of(all);
    int rank(Appointment a) =>
        (a.status == 'requested' || a.status == 'scheduled') ? 0 : 1;
    sorted.sort((a, b) {
      final rankCmp = rank(a).compareTo(rank(b));
      if (rankCmp != 0) return rankCmp;
      return rank(a) == 0
          ? a.dateIso.compareTo(b.dateIso)
          : b.dateIso.compareTo(a.dateIso);
    });
    return sorted;
  }

  /// Reminder preview: pending first (earliest first), then recently done.
  List<FollowUp> _reminderPreview(List<FollowUp> pending, List<FollowUp> done) {
    return [...pending, ...done].take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appointments = context.watch<AppointmentProvider>();
    final prescriptions = context.watch<PrescriptionProvider>();
    final followUps = context.watch<FollowUpProvider>();
    final theme = Theme.of(context);
    final sorted = _sortedAppointments(appointments.appointments);
    final active = sorted
        .where((a) => a.status == 'requested' || a.status == 'scheduled')
        .toList();
    final upNext = active.isEmpty ? null : active.first;
    final confirmed =
        active.where((a) => a.status == 'scheduled').length;
    final awaiting =
        active.where((a) => a.status == 'requested').length;
    final cancelled = appointments.appointments
        .where((a) => a.status == 'cancelled')
        .length;
    final rxItems = prescriptions.prescriptions.take(5).toList();
    final reminderItems =
        _reminderPreview(followUps.pending, followUps.completed);

    // Prescription / reminder sections stay hidden until there is something
    // to show (data, a spinner, or a retry). Their tab screens own the
    // empty states.
    final showRx = prescriptions.prescriptions.isNotEmpty ||
        (prescriptions.isLoading && prescriptions.prescriptions.isEmpty) ||
        (prescriptions.errorMessage.isNotEmpty &&
            prescriptions.prescriptions.isEmpty);
    final showReminders = followUps.followUps.isNotEmpty ||
        (followUps.isLoading && followUps.followUps.isEmpty) ||
        (followUps.errorMessage.isNotEmpty && followUps.followUps.isEmpty);

    return AppScaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('My Care'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_outlined),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bookVisit,
        icon: const Icon(Icons.add),
        label: const Text('Book visit'),
      ),
      floatingActionButtonLocation: patientFabLocation,
      bottomNavigationBar: const PatientBottomNav(currentIndex: 0),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            _WelcomeBanner(name: auth.name),
            const SizedBox(height: 16),
            if (appointments.errorMessage.isNotEmpty)
              ListErrorBanner(
                message: appointments.errorMessage,
                onRetry: _refresh,
                padding: EdgeInsets.zero,
              ),
            // Doctor feedback: surface approval outcomes explicitly.
            // "Cancelled" covers both doctor declines and own cancels —
            // the status alone can't say who cancelled.
            if (!_loading &&
                (confirmed > 0 || cancelled > 0 || awaiting > 0)) ...[
              const SizedBox(height: 12),
              if (confirmed > 0)
                _FeedbackBanner(
                  icon: Icons.check_circle,
                  color: AppColors.successGreen,
                  text:
                      '$confirmed visit${confirmed == 1 ? '' : 's'} confirmed by your doctor',
                ),
              if (awaiting > 0)
                _FeedbackBanner(
                  icon: Icons.schedule_outlined,
                  color: AppColors.warningAmber,
                  text:
                      '$awaiting request${awaiting == 1 ? '' : 's'} awaiting doctor review',
                ),
              if (cancelled > 0)
                _FeedbackBanner(
                  icon: Icons.cancel_outlined,
                  color: AppColors.errorRed,
                  text:
                      '$cancelled booking${cancelled == 1 ? '' : 's'} cancelled',
                ),
            ],
            if (upNext != null) ...[
              const SizedBox(height: 12),
              _UpNextCard(
                appointment: upNext,
                onCancel: () => _cancel(upNext),
              ),
            ],
            const SizedBox(height: 12),
            _SectionTitle(
              title: 'My appointments',
              count: appointments.appointments.length,
            ),
            const SizedBox(height: 8),
            if (_loading && sorted.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (sorted.isEmpty)
              EmptyListState(
                icon: Icons.calendar_month_outlined,
                message: 'No bookings yet. Tap Book visit to see a doctor.',
                actionLabel: 'Book visit',
                onAction: _bookVisit,
              )
            else
              ...sorted.map(
                (a) {
                  return Card(
                    child: ListTile(
                      title: Text(
                        '${a.date} · ${a.time}',
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${a.doctor.isEmpty ? 'Doctor' : a.doctor}'
                            '${a.reason.isEmpty ? '' : ' · ${a.reason}'}',
                          ),
                          const SizedBox(height: 6),
                          StatusChip(status: a.status),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: (a.status == 'requested' ||
                              a.status == 'scheduled')
                          ? TextButton(
                              onPressed: () => _cancel(a),
                              child: const Text('Cancel'),
                            )
                          : null,
                    ),
                  );
                },
              ),
            if (showRx) ...[
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'My prescriptions',
                count: prescriptions.prescriptions.length,
                actionLabel: 'View all',
                onAction: () => Navigator.of(context)
                    .pushNamed('/patient-prescriptions'),
              ),
              const SizedBox(height: 8),
              if (prescriptions.isLoading &&
                  prescriptions.prescriptions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (prescriptions.errorMessage.isNotEmpty &&
                  prescriptions.prescriptions.isEmpty)
                ListErrorBanner(
                  message: prescriptions.errorMessage,
                  onRetry: () => context
                      .read<PrescriptionProvider>()
                      .loadPrescriptions(),
                  padding: EdgeInsets.zero,
                )
              else
                ...rxItems.map(
                  (p) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.medication_outlined),
                      title: Text(p.medicineName),
                      subtitle: Text(
                        '${p.dosage} · ${p.frequency} · ${p.duration}',
                      ),
                    ),
                  ),
                ),
            ],
            if (showReminders) ...[
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'My reminders',
                count: followUps.followUps.length,
                actionLabel: 'View all',
                onAction: () => Navigator.of(context)
                    .pushNamed('/patient-reminders'),
              ),
              const SizedBox(height: 8),
              if (followUps.isLoading && followUps.followUps.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (followUps.errorMessage.isNotEmpty &&
                  followUps.followUps.isEmpty)
                ListErrorBanner(
                  message: followUps.errorMessage,
                  onRetry: () =>
                      context.read<FollowUpProvider>().loadFollowUps(),
                  padding: EdgeInsets.zero,
                )
              else
                ...reminderItems.map(
                  (f) => Card(
                    child: CheckboxListTile(
                      title: Text(f.patientName.isEmpty
                          ? f.dateLabel
                          : '${f.dateLabel} · ${f.patientName}'),
                      subtitle:
                          f.notes.isEmpty ? null : Text(f.notes),
                      value: f.isDone,
                      onChanged: (v) => context
                          .read<FollowUpProvider>()
                          .toggleDone(f.id, v ?? false),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Next active visit, highlighted so the patient sees it at a glance.
class _UpNextCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onCancel;

  const _UpNextCard({required this.appointment, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent =
        isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;
    final canCancel = appointment.status == 'requested' ||
        appointment.status == 'scheduled';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_outlined, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Up next',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              StatusChip(status: appointment.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${appointment.date} · ${appointment.time}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${appointment.doctor.isEmpty ? 'Doctor' : appointment.doctor}'
            '${appointment.reason.isEmpty ? '' : ' · ${appointment.reason}'}',
            style: theme.textTheme.bodyMedium,
          ),
          if (canCancel) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _FeedbackBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final String name;

  const _WelcomeBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final display =
        name.trim().isEmpty ? 'there' : name.trim().split(' ').first;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0E7C7B), const Color(0xFF155E5D)]
              : [const Color(0xFF0E7C7B), const Color(0xFF14A8A6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E7C7B).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $display!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your visits, prescriptions and reminders in one place.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    required this.count,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Text(
          '$count',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
        ],
      ],
    );
  }
}
