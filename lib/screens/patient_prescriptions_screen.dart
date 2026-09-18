import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/prescription_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/list_states.dart';

/// Part 5: patient read-only full prescription list.
class PatientPrescriptionsScreen extends StatefulWidget {
  const PatientPrescriptionsScreen({super.key});

  @override
  State<PatientPrescriptionsScreen> createState() =>
      _PatientPrescriptionsScreenState();
}

class _PatientPrescriptionsScreenState
    extends State<PatientPrescriptionsScreen> {
  Future<void> _reload() =>
      context.read<PrescriptionProvider>().loadPrescriptions();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();
    final items = provider.prescriptions;

    return AppScaffold(
      appBar: AppBar(title: const Text('My prescriptions')),
      body: Column(
        children: [
          if (provider.errorMessage.isNotEmpty)
            ListErrorBanner(
              message: provider.errorMessage,
              onRetry: _reload,
            ),
          Expanded(
            child: provider.isLoading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _reload,
                        child: const SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 300,
                            child: EmptyListState(
                              icon: Icons.medication_outlined,
                              message: 'No prescriptions yet.',
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
                              const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final p = items[i];
                            return Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.medication_outlined,
                                ),
                                title: Text(p.medicineName),
                                subtitle: Text(
                                  '${p.dosage} · ${p.frequency} · ${p.duration}'
                                  '${p.notes.isEmpty ? '' : '\n${p.notes}'}',
                                ),
                                isThreeLine: p.notes.isNotEmpty,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
