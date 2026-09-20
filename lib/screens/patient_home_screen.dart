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
    await Future.wait([
      context.read<PatientProvider>().loadPatients(),
      context.read<AppointmentProvider>().loadAppointments(),
      context.read<PrescriptionProvider>().loadPrescriptions(),
      context.read<FollowUpProvider>().loadFollowUps(),
    ]);
    if (mounted) setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appointments = context.watch<AppointmentProvider>();
    final prescriptions = context.watch<PrescriptionProvider>();
    final followUps = context.watch<FollowUpProvider>();
    final theme = Theme.of(context);
    final confirmed = appointments.appointments
        .where((a) => a.status == 'scheduled')
        .length;
    final declined = appointments.appointments
        .where((a) => a.status == 'cancelled')
        .length;
    final awaiting = appointments.appointments
        .where((a) => a.status == 'requested')
        .length;

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
        onPressed: () => Navigator.of(context).pushNamed('/patient-book'),
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
            if (!_loading &&
                (confirmed > 0 || declined > 0 || awaiting > 0)) ...[
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
              if (declined > 0)
                _FeedbackBanner(
                  icon: Icons.cancel_outlined,
                  color: AppColors.errorRed,
                  text:
                      '$declined request${declined == 1 ? '' : 's'} declined — try another day',
                ),
            ],
            _SectionTitle(
              title: 'My appointments',
              count: appointments.appointments.length,
            ),
            const SizedBox(height: 8),
            if (_loading && appointments.appointments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (appointments.appointments.isEmpty)
              const EmptyListState(
                icon: Icons.calendar_month_outlined,
                message: 'No bookings yet. Tap Book visit to see a doctor.',
              )
            else
              ...appointments.appointments.map(
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
            const SizedBox(height: 16),
            _SectionTitle(
              title: 'My prescriptions',
              count: prescriptions.prescriptions.length,
              actionLabel: 'View all',
              onAction: () => Navigator.of(context)
                  .pushNamed('/patient-prescriptions'),
            ),
            const SizedBox(height: 8),
            if (prescriptions.prescriptions.isEmpty)
              const EmptyListState(
                icon: Icons.medication_outlined,
                message: 'No prescriptions yet.',
              )
            else
              ...prescriptions.prescriptions.take(5).map(
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
            const SizedBox(height: 16),
            _SectionTitle(
              title: 'My reminders',
              count: followUps.followUps.length,
              actionLabel: 'View all',
              onAction: () => Navigator.of(context)
                  .pushNamed('/patient-reminders'),
            ),
            const SizedBox(height: 8),
            if (followUps.followUps.isEmpty)
              const EmptyListState(
                icon: Icons.event_available_outlined,
                message: 'No follow-up reminders.',
              )
            else
              ...followUps.followUps.map(
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
        ),
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
