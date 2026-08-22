import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/patient_list_tile.dart';
import '../widgets/app_add_fab.dart';
import '../utils/app_colors.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const List<Map<String, String>> _patients = [
    {'name': 'John Doe', 'age': '28', 'gender': 'Male', 'lastVisit': '18 May 2025'},
    {'name': 'Emily Smith', 'age': '32', 'gender': 'Female', 'lastVisit': '17 May 2025'},
    {'name': 'Michael Brown', 'age': '45', 'gender': 'Male', 'lastVisit': '15 May 2025'},
    {'name': 'Sarah Johnson', 'age': '29', 'gender': 'Female', 'lastVisit': '14 May 2025'},
    {'name': 'David Wilson', 'age': '50', 'gender': 'Male', 'lastVisit': '10 May 2025'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredPatients {
    if (_query.trim().isEmpty) return _patients;
    return _patients
        .where((p) => p['name']!.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.screenTintedBackground,
      appBar: AppBar(
        backgroundColor: AppColors.screenTintedBackground,
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
            child: _filteredPatients.isEmpty
                ? Center(
              child: Text(
                'No patients found',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _filteredPatients.length,
              itemBuilder: (context, index) {
                final patient = _filteredPatients[index];
                return PatientListTile(
                  name: patient['name']!,
                  age: patient['age']!,
                  gender: patient['gender']!,
                  lastVisit: patient['lastVisit']!,
                  onTap: () => Navigator.of(context).pushNamed('/patient-details'),
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