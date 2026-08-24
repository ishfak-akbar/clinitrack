import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_add_fab.dart';
import '../widgets/appointment_list_tile.dart';
import '../providers/appointment_provider.dart';
import '../providers/patient_provider.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

enum FilterOption { all, scheduled, completed }

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  FilterOption _filter = FilterOption.all;

  List<Appointment> _filteredAppointments(List<Appointment> all) {
    if (_filter == FilterOption.all) return all;
    final targetStatus = _filter == FilterOption.scheduled ? 'scheduled' : 'completed';
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

  @override
  Widget build(BuildContext context) {
    final allAppointments = context.watch<AppointmentProvider>().appointments;
    final filtered = _filteredAppointments(allAppointments);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Appointments'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _filterChip('All', FilterOption.all),
                _filterChip('Scheduled', FilterOption.scheduled),
                _filterChip('Completed', FilterOption.completed),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
              child: Text(
                'No appointments found',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final appt = filtered[index];
                return AppointmentListTile(
                  patientName: appt.patientName,
                  time: appt.time,
                  reason: appt.reason,
                  status: appt.status == 'completed'
                      ? AppointmentStatus.completed
                      : AppointmentStatus.scheduled,
                  onStatusChanged: (newStatus) {
                    context.read<AppointmentProvider>().updateStatus(
                      appt.id,
                      newStatus == AppointmentStatus.completed ? 'completed' : 'scheduled',
                    );
                  },
                  onTap: () {
                    final allPatients = context.read<PatientProvider>().patients;
                    final matching = allPatients.where((p) => p.id == appt.patientId);
                    Navigator.of(context).pushNamed(
                      '/patient-details',
                      arguments: matching.isNotEmpty ? matching.first : null,
                    );
                  },
                );
              },
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