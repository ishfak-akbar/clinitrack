import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/stats_service.dart';
import '../utils/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/app_add_fab.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/follow_up_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/stats_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_drawer.dart';
import '../widgets/list_states.dart';
import '../widgets/user_avatar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Stats are prefetched in splash; refresh here in case data changed
    // while away (e.g. after adding a patient/appointment).
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStats());
  }

  Future<void> _refreshStats() async {
    await Future.wait([
      context.read<AppointmentProvider>().loadAppointments(),
      context.read<FollowUpProvider>().loadFollowUps(),
      context.read<MedicineProvider>().loadMedicines(),
    ]);
    if (!mounted) return;
    await context.read<StatsProvider>().refresh(
          patients: context.read<PatientProvider>().patients,
          appointments: context.read<AppointmentProvider>().appointments,
          prescriptions: context.read<PrescriptionProvider>().prescriptions,
          followUps: context.read<FollowUpProvider>().followUps,
          medicines: context.read<MedicineProvider>().medicines,
        );
  }

  String _greeting(String name) {
    final hour = DateTime.now().hour;
    final part = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final display = name.trim().isEmpty ? 'Doctor' : name.trim();
    return '$part, $display!';
  }

  String _todayLabel() {
    final now = DateTime.now();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${weekdays[now.weekday - 1]} ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final statsState = context.watch<StatsProvider>();
    final stats = statsState.stats;
    final auth = context.watch<AuthProvider>();
    final doctorName = auth.name;
    final appointments = context.watch<AppointmentProvider>().appointments;
    final followUps = context.watch<FollowUpProvider>().followUps;
    final medicines = context.watch<MedicineProvider>().medicines;

    final today = StatsService.todayIso();
    final todaysAppointments =
        appointments.where((a) => a.dateIso == today).take(4).toList();
    final requestedCount =
        appointments.where((a) => a.status == 'requested').length;
    final overdueFollowUps = followUps
        .where((f) => !f.isDone && f.dateIso.isNotEmpty && f.dateIso.compareTo(today) < 0)
        .length;
    final lowStock = medicines.where((m) => m.stock < 40).length;

    return AppScaffold(
      extendBody: true,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/profile'),
              child: UserAvatar(
                avatarUrl: auth.avatarUrl,
                name: doctorName,
                radius: 18,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStats,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Text(
              _greeting(doctorName),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_todayLabel()} · ${auth.clinicAddress.isEmpty ? 'My clinic' : auth.clinicAddress}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (statsState.errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              ListErrorBanner(
                message: statsState.errorMessage,
                onRetry: _refreshStats,
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
            ],
            if (requestedCount + overdueFollowUps + lowStock > 0) ...[
              const SizedBox(height: 12),
              _NeedsAttentionCard(
                requested: requestedCount,
                overdue: overdueFollowUps,
                lowStock: lowStock,
              ),
            ],
            const SizedBox(height: 16),

            // ---------- Stat cards (Step 13: server-side counts) ----------
            Row(
              children: [
                Expanded(
                  child: DashboardStatCard(
                    icon: Icons.calendar_today_outlined,
                    label: "Today's\nAppointments",
                    value: '${stats.todayAppointments}',
                    iconColor: const Color(0xFF3B82F6),
                    lightIconBackground: const Color(0xFFE0EBFD),
                    lightCardBackground: const Color(0xFFF3F8FF),
                    onTap: () => Navigator.of(context)
                        .pushNamed('/appointments'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DashboardStatCard(
                    icon: Icons.people_outline,
                    label: 'Total\nPatients',
                    value: '${stats.totalPatients}',
                    iconColor: AppColors.successGreen,
                    lightIconBackground: const Color(0xFFE3F6ED),
                    lightCardBackground: const Color(0xFFF2FBF6),
                    onTap: () => Navigator.of(context)
                        .pushNamed('/patient-list'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DashboardStatCard(
                    icon: Icons.schedule_outlined,
                    label: 'Follow-ups\nDue',
                    value: '${stats.followUpsDue}',
                    iconColor: AppColors.followUpOrange,
                    lightIconBackground: AppColors.followUpOrangeLight,
                    lightCardBackground: AppColors.followUpOrangeCard,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/follow-ups'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              "Today's Appointments",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),

            // ---------- Appointment list ----------
            if (todaysAppointments.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No appointments today.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      for (int i = 0; i < todaysAppointments.length; i++) ...[
                        _AppointmentRow(appointment: todaysAppointments[i]),
                        if (i != todaysAppointments.length - 1)
                          const Divider(),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: const AppAddFab(routeName: '/add-appointment'),
      floatingActionButtonLocation: const AppFabAboveNavLocation(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _NeedsAttentionCard extends StatelessWidget {
  final int requested;
  final int overdue;
  final int lowStock;

  const _NeedsAttentionCard({
    required this.requested,
    required this.overdue,
    required this.lowStock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                'Needs attention',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (requested > 0)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.mark_email_unread_outlined,
                    color: Color(0xFF3B82F6)),
                title: Text('$requested booking request${requested == 1 ? '' : 's'}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.of(context).pushNamed('/appointments'),
              ),
            if (overdue > 0)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_outlined,
                    color: AppColors.followUpOrange),
                title: Text('$overdue overdue follow-up${overdue == 1 ? '' : 's'}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.of(context).pushNamed('/follow-ups'),
              ),
            if (lowStock > 0)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.errorRed),
                title: Text('$lowStock low-stock medicine${lowStock == 1 ? '' : 's'}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.of(context).pushNamed('/medicine-list'),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  final Appointment appointment;

  const _AppointmentRow({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

    return ListTile(
      onTap: () {
        final allPatients = context.read<PatientProvider>().patients;
        final matching = allPatients.where((p) => p.id == appointment.patientId);
        Navigator.of(context).pushNamed(
          '/patient-details',
          arguments: matching.isNotEmpty ? matching.first : null,
        );
      },
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: accent.withValues(alpha: 0.12),
        child: Text(
          appointment.patientName.isNotEmpty ? appointment.patientName.substring(0, 1) : '?',
          style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      title: Text(appointment.patientName, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text('${appointment.time} · ${appointment.reason}'),
      trailing: const Icon(Icons.chevron_right, color: AppColors.iconGray),
    );
  }
}
