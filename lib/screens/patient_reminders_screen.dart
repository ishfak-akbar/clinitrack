import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/follow_up_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/list_states.dart';

/// Part 5: patient reminders with Pending/Done sections (toggle allowed).
class PatientRemindersScreen extends StatefulWidget {
  const PatientRemindersScreen({super.key});

  @override
  State<PatientRemindersScreen> createState() =>
      _PatientRemindersScreenState();
}

class _PatientRemindersScreenState extends State<PatientRemindersScreen> {
  Future<void> _reload() =>
      context.read<FollowUpProvider>().loadFollowUps();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FollowUpProvider>();
    final pending = provider.pending;
    final done = provider.completed;

    return AppScaffold(
      appBar: AppBar(title: const Text('My reminders')),
      body: Column(
        children: [
          if (provider.errorMessage.isNotEmpty)
            ListErrorBanner(
              message: provider.errorMessage,
              onRetry: _reload,
            ),
          Expanded(
            child: provider.isLoading &&
                    pending.isEmpty &&
                    done.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : pending.isEmpty && done.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _reload,
                        child: const SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 300,
                            child: EmptyListState(
                              icon:
                                  Icons.event_available_outlined,
                              message: 'No follow-up reminders.',
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            if (pending.isNotEmpty)
                              _Section(
                                title: 'Pending (${pending.length})',
                                items: pending,
                              ),
                            if (pending.isNotEmpty && done.isNotEmpty)
                              const SizedBox(height: 12),
                            if (done.isNotEmpty)
                              _Section(
                                title: 'Done (${done.length})',
                                items: done,
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<FollowUp> items;

  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (final f in items)
              CheckboxListTile(
                title: Text(
                  f.dateLabel.isEmpty
                      ? (f.time.isEmpty ? 'Reminder' : f.time)
                      : '${f.dateLabel}${f.time.isEmpty ? '' : ' · ${f.time}'}',
                ),
                subtitle:
                    f.notes.isEmpty ? null : Text(f.notes),
                value: f.isDone,
                onChanged: (v) => context
                    .read<FollowUpProvider>()
                    .toggleDone(f.id, v ?? false),
              ),
          ],
        ),
      ),
    );
  }
}
