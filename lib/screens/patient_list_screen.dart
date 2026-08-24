import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/patient_list_tile.dart';
import '../widgets/app_add_fab.dart';
import '../utils/app_colors.dart';
import '../providers/patient_provider.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Patient> _filteredPatients(List<Patient> allPatients) {
    if (_query.trim().isEmpty) return allPatients;
    return allPatients
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final allPatients = context.watch<PatientProvider>().patients;
    final filtered = _filteredPatients(allPatients);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Patient List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
              child: Text(
                'No patients found',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final patient = filtered[index];
                return PatientListTile(
                  name: patient.name,
                  age: patient.age,
                  gender: patient.gender,
                  lastVisit: patient.lastVisit,
                  onTap: () => Navigator.of(context).pushNamed('/patient-details', arguments: patient),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: const AppAddFab(routeName: '/add-patient'),
      floatingActionButtonLocation: const AppFabAboveNavLocation(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}