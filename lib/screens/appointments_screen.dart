import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_add_fab.dart';
import '../widgets/appointment_list_tile.dart';
import '../utils/app_colors.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentFilter { }
enum FilterOption { all, scheduled, completed }

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  FilterOption _filter = FilterOption.all;

  final List<Map<String, dynamic>> _appointments = [
    {'name': 'John Doe', 'time': '09:00 AM', 'reason': 'General Checkup', 'status': AppointmentStatus.scheduled},
    {'name': 'Emily Smith', 'time': '10:30 AM', 'reason': 'Fever & Cold', 'status': AppointmentStatus.scheduled},
    {'name': 'Michael Brown', 'time': '12:00 PM', 'reason': 'Follow-up', 'status': AppointmentStatus.completed},
    {'name': 'Sarah Johnson', 'time': '02:30 PM', 'reason': 'Consultation', 'status': AppointmentStatus.completed},
  ];

  List<Map<String, dynamic>> get _filteredAppointments {
    if (_filter == FilterOption.all) return _appointments;
    final targetStatus = _filter == FilterOption.scheduled
        ? AppointmentStatus.scheduled
        : AppointmentStatus.completed;
    return _appointments.where((a) => a['status'] == targetStatus).toList();
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
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.screenTintedBackground,
      appBar: AppBar(
        backgroundColor: AppColors.screenTintedBackground,
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
            child: _filteredAppointments.isEmpty
                ? Center(
              child: Text(
                'No appointments found',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _filteredAppointments.length,
              itemBuilder: (context, index) {
                final appt = _filteredAppointments[index];
                return AppointmentListTile(
                  patientName: appt['name'],
                  time: appt['time'],
                  reason: appt['reason'],
                  status: appt['status'],
                  onStatusChanged: (newStatus) {
                    setState(() => appt['status'] = newStatus);
                  },
                  onTap: () => Navigator.of(context).pushNamed('/patient-details'),
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