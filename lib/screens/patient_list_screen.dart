import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/patient_list_tile.dart';
import '../widgets/app_add_fab.dart';
import '../widgets/list_states.dart';
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
  void initState() {
    super.initState();
    // Dashboard stats come from fresh server COUNT(*) on every open,
    // but this list only showed whatever splash loaded — so a patient
    // created afterwards (e.g. portal signup) made the count and the
    // list disagree until manual pull-to-refresh. Load on entry.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

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

  Future<void> _reload() =>
      context.read<PatientProvider>().loadPatients();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();
    final filtered = _filteredPatients(provider.patients);
    final isSearching = _query.trim().isNotEmpty;

    return AppScaffold(
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
                              icon: Icons.people_outline,
                              message: isSearching
                                  ? 'No patients match your search'
                                  : 'No patients yet',
                              actionLabel: isSearching
                                  ? null
                                  : 'Add patient',
                              onAction: isSearching
                                  ? null
                                  : () => Navigator.of(context)
                                      .pushNamed('/add-patient'),
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
                              const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
          ),
        ],
      ),
      floatingActionButton: const AppAddFab(routeName: '/add-patient'),
      floatingActionButtonLocation: const AppFabAboveNavLocation(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}
