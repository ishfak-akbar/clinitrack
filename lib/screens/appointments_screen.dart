import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_add_fab.dart';
import '../widgets/appointment_list_tile.dart';
import '../widgets/list_states.dart';
import '../providers/appointment_provider.dart';
import '../providers/patient_provider.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

enum FilterOption { all, requested, scheduled, completed, cancelled }

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  FilterOption _filter = FilterOption.all;

  List<Appointment> _filteredAppointments(List<Appointment> all) {
    if (_filter == FilterOption.all) return all;
    final targetStatus = switch (_filter) {
      FilterOption.requested => 'requested',
      FilterOption.scheduled => 'scheduled',
      FilterOption.completed => 'completed',
      FilterOption.cancelled => 'cancelled',
      FilterOption.all => '',
    };
    return all.where((a) => a.status == targetStatus).toList();
  }

  Widget _filterChip(String label, FilterOption value) {
    final bool isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  String get _emptyMessage => switch (_filter) {
        FilterOption.requested => 'No appointment requests',
        FilterOption.scheduled => 'No scheduled appointments',
        FilterOption.completed => 'No completed appointments',
        FilterOption.cancelled => 'No cancelled appointments',
        FilterOption.all => 'No appointments yet',
      };

  AppointmentStatus _toStatus(String s) => switch (s) {
        'completed' => AppointmentStatus.completed,
        'requested' => AppointmentStatus.requested,
        'cancelled' => AppointmentStatus.cancelled,
        _ => AppointmentStatus.scheduled,
      };

  String _fromStatus(AppointmentStatus s) => switch (s) {
        AppointmentStatus.completed => 'completed',
        AppointmentStatus.requested => 'requested',
        AppointmentStatus.cancelled => 'cancelled',
        AppointmentStatus.scheduled => 'scheduled',
      };

  Future<void> _reload() =>
      context.read<AppointmentProvider>().loadAppointments();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    final filtered = _filteredAppointments(provider.appointments);

    return AppScaffold(
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Appointments'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', FilterOption.all),
                  _filterChip('Requested', FilterOption.requested),
                  _filterChip('Scheduled', FilterOption.scheduled),
                  _filterChip('Completed', FilterOption.completed),
                  _filterChip('Cancelled', FilterOption.cancelled),
                ],
              ),
            ),
          ),
          if (provider.errorMessage.isNotEmpty)
            ListErrorBanner(
              message: provider.errorMessage,
              onRetry: _reload,
            ),
          Expanded(
            child: provider.isLoading && filtered.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _reload,
                        child: SingleChildScrollView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.5,
                            child: EmptyListState(
                              icon: Icons.event_note_outlined,
                              message: _emptyMessage,
                              actionLabel: _filter == FilterOption.all
                                  ? 'Add appointment'
                                  : null,
                              onAction: _filter == FilterOption.all
                                  ? () => Navigator.of(context)
                                      .pushNamed('/add-appointment')
                                  : null,
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final appt = filtered[index];
                            return AppointmentListTile(
                              patientName: appt.patientName,
                              time: appt.time,
                              reason: appt.reason,
                              status: _toStatus(appt.status),
                              onStatusChanged: (newStatus) {
                                context.read<AppointmentProvider>().updateStatus(
                                  appt.id,
                                  _fromStatus(newStatus),
                                );
                              },
                              onTap: () {
                                final allPatients = context.read<PatientProvider>().patients;
                                final matching = allPatients.where((p) => p.id == appt.patientId);
                                if (matching.isNotEmpty) {
                                  Navigator.of(context).pushNamed(
                                    '/patient-details',
                                    arguments: matching.first,
                                  );
                                } else {
                                  // Portal booking: linked row not in doctor list —
                                  // show a read-only record built from the booking.
                                  Navigator.of(context).pushNamed(
                                    '/patient-details',
                                    arguments: Patient(
                                      id: appt.patientId ?? '',
                                      name: appt.patientName,
                                      age: '',
                                      gender: '',
                                      contact: '',
                                      bloodGroup: '',
                                      medicalHistory: '',
                                      allergies: const [],
                                      lastVisit: appt.date,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: const AppAddFab(routeName: '/add-appointment'),
      floatingActionButtonLocation: const AppFabAboveNavLocation(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}
