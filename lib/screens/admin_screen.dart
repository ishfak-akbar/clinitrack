import 'package:flutter/material.dart';

import '../repositories/auth_repository.dart';
import '../utils/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_drawer.dart';
import '../widgets/list_states.dart';

/// Step 5: the whole admin back office — one review queue, nothing more.
/// Lists pending doctor applications with full credentials; approve or
/// reject (rejections require a reason the doctor will see). Entry is
/// restricted by `RoleGuard(adminOnly: true)`; RLS + the
/// `prevent_self_verification()` trigger are the real enforcement.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AuthRepository _repo = AuthRepository();

  List<DoctorApplicationEntry> _queue = [];
  bool _loading = false;
  String _errorMessage = '';
  String? _actingId;

  bool get _offline => !_repo.useBackend;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    if (_loading || _offline) return;
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    try {
      final rows = await _repo.fetchPendingDoctors();
      if (!mounted) return;
      setState(() => _queue = rows);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage =
          'Could not load applications. Check connection and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(DoctorApplicationEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve application?'),
        content: Text(
          '${entry.name.isEmpty ? 'This doctor' : entry.name} will get full '
          'access and appear in the patient directory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _verdict(entry, approve: true);
  }

  Future<void> _reject(DoctorApplicationEntry entry) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const RejectReasonDialog(),
    );
    if (reason == null || reason.trim().isEmpty || !mounted) return;
    await _verdict(entry, approve: false, reason: reason.trim());
  }

  Future<void> _verdict(
    DoctorApplicationEntry entry, {
    required bool approve,
    String reason = '',
  }) async {
    setState(() => _actingId = entry.id);
    try {
      await _repo.reviewDoctor(id: entry.id, approve: approve, reason: reason);
      if (!mounted) return;
      setState(() {
        _queue = _queue.where((e) => e.id != entry.id).toList();
        _actingId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Doctor approved' : 'Application rejected'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _actingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _actingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save review. Try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text('Review applications${_queue.isEmpty ? '' : ' (${_queue.length})'}'),
      ),
      drawer: const AppDrawer(),
      body: _offline
          ? const EmptyListState(
              icon: Icons.cloud_off_outlined,
              message: 'Admin review needs a Supabase connection.',
            )
          : Column(
              children: [
                if (_errorMessage.isNotEmpty)
                  ListErrorBanner(
                    message: _errorMessage,
                    onRetry: _reload,
                  ),
                Expanded(
                  child: _loading && _queue.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _queue.isEmpty
                          ? RefreshIndicator(
                              onRefresh: _reload,
                              child: const SingleChildScrollView(
                                physics: AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height: 300,
                                  child: EmptyListState(
                                    icon: Icons.verified_outlined,
                                    message:
                                        'No pending applications. All caught up.',
                                  ),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _reload,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 32),
                                itemCount: _queue.length,
                                itemBuilder: (context, i) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 12),
                                  child: _ApplicationCard(
                                    entry: _queue[i],
                                    acting: _actingId == _queue[i].id,
                                    busy: _actingId != null,
                                    onApprove: () => _approve(_queue[i]),
                                    onReject: () => _reject(_queue[i]),
                                  ),
                                ),
                              ),
                            ),
                ),
              ],
            ),
    );
  }
}

/// One application: identity header, credential rows, approve/reject.
class _ApplicationCard extends StatelessWidget {
  final DoctorApplicationEntry entry;
  final bool acting;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApplicationCard({
    required this.entry,
    required this.acting,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent =
        isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;
    final name = entry.name.isEmpty ? 'Unnamed doctor' : entry.name;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: accent.withValues(alpha: 0.12),
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1) : '?',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (entry.email.isNotEmpty)
                        Text(
                          entry.email,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (entry.appliedLabel.isNotEmpty)
                  Text(
                    'Applied ${entry.appliedLabel}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.assignment_ind_outlined,
              label: 'Title',
              value: entry.title,
            ),
            _DetailRow(
              icon: Icons.workspace_premium_outlined,
              label: 'Degree',
              value: entry.degree,
            ),
            _DetailRow(
              icon: Icons.account_balance_outlined,
              label: 'Graduated from',
              value: entry.graduatingInstitution.isEmpty
                  ? ''
                  : entry.graduationYear.isEmpty
                      ? entry.graduatingInstitution
                      : '${entry.graduatingInstitution} · ${entry.graduationYear}',
            ),
            _DetailRow(
              icon: Icons.medical_services_outlined,
              label: 'Specialties',
              value: entry.specialtyLine,
            ),
            _DetailRow(
              icon: Icons.badge_outlined,
              label: 'License',
              value: entry.licenseNumber,
            ),
            _DetailRow(
              icon: Icons.business_outlined,
              label: 'Chamber',
              value: [
                entry.chamberName,
                entry.clinicAddress,
              ].where((e) => e.isNotEmpty).join(' — '),
            ),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: entry.phone,
            ),
            _DetailRow(
              icon: Icons.school_outlined,
              label: 'Other qualifications',
              value: entry.qualifications,
            ),
            _DetailRow(
              icon: Icons.work_history_outlined,
              label: 'Experience',
              value: entry.experienceYears.isEmpty
                  ? ''
                  : '${entry.experienceYears} years',
            ),
            if (entry.bio.isNotEmpty)
              _DetailRow(
                icon: Icons.info_outline,
                label: 'About',
                value: entry.bio,
              ),
            const SizedBox(height: 12),
            if (acting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onReject,
                      icon: const Icon(
                        Icons.close_outlined,
                        color: AppColors.errorRed,
                        size: 18,
                      ),
                      label: const Text(
                        'Reject',
                        style: TextStyle(color: AppColors.errorRed),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: busy ? null : onApprove,
                      icon: const Icon(Icons.check_outlined, size: 18),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Credential row; renders nothing when the value is empty.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.listTileTheme.iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 1),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rejection dialog: a reason is mandatory because the doctor sees it.
/// Returns the trimmed reason via pop, or null on cancel.
class RejectReasonDialog extends StatefulWidget {
  const RejectReasonDialog({super.key});

  @override
  State<RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<RejectReasonDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _controller.text.trim();
    if (reason.isEmpty) {
      setState(
        () => _error = 'A reason is required — the doctor will see it.',
      );
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject application?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            maxLines: 3,
            autofocus: true,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              labelText: 'Reason',
              hintText: 'e.g. License number could not be verified…',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: _submit,
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
