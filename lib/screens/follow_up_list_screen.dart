import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/follow_up_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/list_states.dart';

/// Follow-up reminders: pending + done, with complete/undo and delete.
class FollowUpListScreen extends StatefulWidget {
  const FollowUpListScreen({super.key});

  @override
  State<FollowUpListScreen> createState() => _FollowUpListScreenState();
}

class _FollowUpListScreenState extends State<FollowUpListScreen> {
  @override
  void initState() {
    super.initState();
    // Load on entry so reminders never show stale splash-time data.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() =>
      context.read<FollowUpProvider>().loadFollowUps();

  Future<void> _toggle(FollowUp item, bool done) async {
    final ok =
        await context.read<FollowUpProvider>().toggleDone(item.id, done);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context
                  .read<FollowUpProvider>()
                  .errorMessage
                  .isEmpty
              ? 'Could not update follow-up'
              : context.read<FollowUpProvider>().errorMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _delete(FollowUp item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reminder'),
        content: Text('Delete the follow-up for ${item.patientName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok =
        await context.read<FollowUpProvider>().deleteFollowUp(item.id);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context
                  .read<FollowUpProvider>()
                  .errorMessage
                  .isEmpty
              ? 'Could not delete follow-up'
              : context.read<FollowUpProvider>().errorMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _row(FollowUp item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent =
        isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: item.isDone,
        activeColor: accent,
        onChanged: (value) => _toggle(item, value ?? false),
      ),
      title: Text(
        item.patientName,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              decoration:
                  item.isDone ? TextDecoration.lineThrough : null,
            ),
      ),
      subtitle: Text(
        '${item.dateLabel}${item.time.isNotEmpty ? ' • ${item.time}' : ''}'
        '${item.notes.isNotEmpty ? '\n${item.notes}' : ''}',
      ),
      isThreeLine: item.notes.isNotEmpty,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
        onPressed: () => _delete(item),
      ),
    );
  }

  Widget _section(String title, List<FollowUp> items) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$title (${items.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (var i = 0; i < items.length; i++) ...[
              _row(items[i]),
              if (i != items.length - 1) const Divider(),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FollowUpProvider>();
    final pending = provider.pending;
    final done = provider.completed;

    return AppScaffold(
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Follow-ups'),
      ),
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
                        child: SingleChildScrollView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height *
                                0.5,
                            child: const EmptyListState(
                              icon: Icons.event_available_outlined,
                              message: 'No follow-up reminders',
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                              16, 8, 16, 100),
                          children: [
                            if (pending.isNotEmpty)
                              _section('Pending', pending),
                            if (pending.isNotEmpty &&
                                done.isNotEmpty)
                              const SizedBox(height: 12),
                            if (done.isNotEmpty)
                              _section('Done', done),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
