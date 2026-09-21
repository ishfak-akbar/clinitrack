import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../repositories/auth_repository.dart';
import '../utils/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/doctor_card.dart';
import '../widgets/form_section_card.dart';
import '../widgets/list_states.dart';
import '../widgets/section_label.dart';
import '../widgets/themed_choice_chip.dart';

/// Book visit — guided 3-step flow: 1 Doctor → 2 Schedule → 3 Details.
/// Opened with push (never replace) so the AppBar back button always works.
class PatientBookScreen extends StatefulWidget {
  const PatientBookScreen({super.key});

  @override
  State<PatientBookScreen> createState() => _PatientBookScreenState();
}

class _PatientBookScreenState extends State<PatientBookScreen> {
  static const _labels = ['Doctor', 'Schedule', 'Details'];

  final _reasonController = TextEditingController();
  final _authRepo = AuthRepository();

  List<DoctorDirectoryEntry> _doctors = [];
  String? _selectedDoctorId;
  DateTime? _date;
  TimeOfDay? _time;

  int _step = 0;
  bool _loadingDoctors = true;
  String _doctorsError = '';
  bool _isSaving = false;
  bool _sent = false;

  DoctorDirectoryEntry? get _selectedDoctor {
    if (_selectedDoctorId == null) return null;
    for (final d in _doctors) {
      if (d.id == _selectedDoctorId) return d;
    }
    return null;
  }

  bool get _doctorValid => _selectedDoctor != null;
  bool get _scheduleValid => _date != null && _time != null;
  bool get _detailsValid =>
      _reasonController.text.trim().isNotEmpty;

  bool get _canContinue {
    if (_step == 0) return _doctorValid;
    if (_step == 1) return _scheduleValid;
    return _detailsValid && !_isSaving;
  }

  String get _continueHint {
    if (_step == 0 && !_doctorValid) return 'Select a doctor to continue';
    if (_step == 1 && !_scheduleValid) {
      return _date == null
          ? 'Pick a date to continue'
          : 'Pick a time slot to continue';
    }
    if (_step == 2 && !_detailsValid) {
      return 'Add a reason so your doctor can prepare';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final patientProvider = context.read<PatientProvider>();
    await patientProvider.loadPatients();
    // ignore: use_build_context_synchronously
    await patientProvider.fetchMyLinked();
    if (!mounted) return;
    await _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _loadingDoctors = true;
      _doctorsError = '';
    });
    try {
      final rows = await _authRepo.fetchDoctors();
      if (!mounted) return;
      // Local/offline mode has no directory — show sample cards so new
      // users instantly understand the booking flow.
      final effective =
          rows.isEmpty && !_authRepo.useBackend ? _demoDoctors : rows;
      setState(() {
        _doctors = effective;
        if (_selectedDoctorId == null && effective.isNotEmpty) {
          _selectedDoctorId = effective.first.id;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _doctorsError =
          'Could not load doctors. Check connection and retry.');
    } finally {
      if (mounted) setState(() => _loadingDoctors = false);
    }
  }

  List<DoctorDirectoryEntry> get _demoDoctors => const [
        DoctorDirectoryEntry(
          id: 'demo-1',
          name: 'Dr. Sarah Rahman',
          specialty: 'Cardiology',
          qualifications: 'MBBS, MD (Cardiology)',
          experienceYears: '8',
          clinicAddress: 'Zindabazar, Sylhet',
          bio: 'Heart care, hypertension and preventive cardiology.',
        ),
        DoctorDirectoryEntry(
          id: 'demo-2',
          name: 'Dr. Tanvir Ahmed',
          specialty: 'General Physician',
          qualifications: 'MBBS, FCPS (Medicine)',
          experienceYears: '5',
          clinicAddress: 'Ambarkhana, Sylhet',
          bio: 'Fever, diabetes follow-ups and general consultations.',
        ),
        DoctorDirectoryEntry(
          id: 'demo-3',
          name: 'Dr. Nabila Karim',
          specialty: 'Pediatrics',
          qualifications: 'MBBS, DCH',
          experienceYears: '6',
          clinicAddress: 'Mirboxtula, Sylhet',
          bio: 'Child health, vaccination and growth monitoring.',
        ),
      ];

  // ---------- Schedule helpers ----------

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? start,
      firstDate: start,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        // Clear a slot that is no longer valid for the new day.
        if (_time != null && _isSlotDisabled(_time!)) _time = null;
      });
    }
  }

  /// Clinic slots 9:00 AM – 5:00 PM every 30 min (no free-form times,
  /// so patients can't double-book odd hours).
  List<TimeOfDay> get _slots => [
        for (int m = 9 * 60; m <= 17 * 60; m += 30)
          TimeOfDay(hour: m ~/ 60, minute: m % 60),
      ];

  bool _isTodaySelected() {
    if (_date == null) return false;
    final now = DateTime.now();
    return _date!.year == now.year &&
        _date!.month == now.month &&
        _date!.day == now.day;
  }

  bool _isSlotDisabled(TimeOfDay slot) {
    if (!_isTodaySelected()) return false;
    final now = TimeOfDay.now();
    final slotMins = slot.hour * 60 + slot.minute;
    final nowMins = now.hour * 60 + now.minute;
    return slotMins <= nowMins + 30; // 30-min buffer
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Canonical "same doctor?" check: owner_id first, display name as legacy
  /// fallback (local rows created before owner ids were preserved).
  bool _isSameDoctor(
      String? ownerId, String doctorName, DoctorDirectoryEntry doctor) {
    if (ownerId != null && ownerId.isNotEmpty) {
      return ownerId == doctor.id;
    }
    return doctorName.trim().toLowerCase() ==
        doctor.name.trim().toLowerCase();
  }

  // ---------- Flow ----------

  void _next() {
    if (!_canContinue) return;
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _submit() async {
    final doctor = _selectedDoctor;
    if (doctor == null || _date == null || _time == null) return;
    if (_reasonController.text.trim().isEmpty) return;

    final patientProvider = context.read<PatientProvider>();
    final myPatient = patientProvider.myLinked;
    if (myPatient == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your patient profile is not linked yet. Pull to refresh on My Care and retry.',
          ),
        ),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    // Prefer the linked patient row name (source of truth for bookings);
    // fall back to the auth display name.
    final displayName = myPatient.name.trim().isNotEmpty
        ? myPatient.name.trim()
        : auth.name.trim();
    final iso = _iso(_date!);

    // Avoid duplicate active requests for the same doctor + day.
    // Canonical match is owner_id (doctor id) — the display-name snapshot
    // drifts when a doctor renames their profile, so name is only a
    // fallback for legacy local rows that carry no owner id.
    final existing =
        context.read<AppointmentProvider>().appointments.where(
              (a) =>
                  _isSameDoctor(a.ownerId, a.doctor, doctor) &&
                  a.dateIso == iso &&
                  (a.status == 'requested' || a.status == 'scheduled'),
            );
    if (existing.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already have an active request for this day'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final ok = await context.read<AppointmentProvider>().addAppointment(
          Appointment(
            id: '',
            patientId: myPatient.id,
            patientName: displayName,
            date: _fmtDate(_date!),
            dateIso: iso,
            time: _fmtTime(_time!),
            reason: _reasonController.text.trim(),
            doctor: doctor.name,
            status: 'requested',
          ),
          ownerId: doctor.id,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context
                  .read<AppointmentProvider>()
                  .errorMessage
                  .isEmpty
              ? 'Could not send request'
              : context.read<AppointmentProvider>().errorMessage),
        ),
      );
      return;
    }
    setState(() => _sent = true);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AppScaffold(
        appBar: AppBar(title: const Text('Book visit')),
        body: _sent
            ? _SuccessView(
                doctor: _selectedDoctor,
                dateLabel:
                    _date == null ? '' : _fmtDate(_date!),
                timeLabel:
                    _time == null ? '' : _fmtTime(_time!),
              )
            : Column(
                children: [
                  _StepHeader(step: _step, labels: _labels),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _stepBody(),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: _sent
            ? null
            : _StepBar(
                step: _step,
                isLast: _step == 2,
                isSaving: _isSaving,
                canContinue: _canContinue,
                hint: _continueHint,
                onBack: _back,
                onNext: _next,
              ),
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _DoctorStep(
          key: const ValueKey('step-doctor'),
          loading: _loadingDoctors,
          error: _doctorsError,
          doctors: _doctors,
          selectedId: _selectedDoctorId,
          onRetry: _loadDoctors,
          onSelect: (id) => setState(() => _selectedDoctorId = id),
          onViewProfile: (d) => showDoctorProfileSheet(context, d),
        );
      case 1:
        return _ScheduleStep(
          key: const ValueKey('step-schedule'),
          date: _date,
          time: _time,
          slots: _slots,
          isSlotDisabled: _isSlotDisabled,
          fmtDate: _fmtDate,
          fmtTime: _fmtTime,
          onPickDate: _pickDate,
          onPickSlot: (s) => setState(() => _time = s),
        );
      default:
        return _DetailsStep(
          key: const ValueKey('step-details'),
          doctor: _selectedDoctor,
          dateLabel: _date == null ? '—' : _fmtDate(_date!),
          timeLabel: _time == null ? '—' : _fmtTime(_time!),
          reasonController: _reasonController,
          onChanged: (_) => setState(() {}),
        );
    }
  }
}

// ---------- Step progress header ----------

class _StepHeader extends StatelessWidget {
  final int step;
  final List<String> labels;

  const _StepHeader({required this.step, required this.labels});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent =
        isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      if (i > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i <= step
                                ? accent
                                : muted.withValues(alpha: 0.3),
                          ),
                        ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < step
                              ? accent
                              : i == step
                                  ? accent.withValues(alpha: 0.15)
                                  : Colors.transparent,
                          border: Border.all(
                            color: i <= step
                                ? accent
                                : muted.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: i < step
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: i == step ? accent : muted,
                                  ),
                                ),
                        ),
                      ),
                      if (i < labels.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i < step
                                ? accent
                                : muted.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight:
                          i == step ? FontWeight.w700 : FontWeight.w400,
                      color: i <= step ? accent : muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------- Step 1: doctor ----------

class _DoctorStep extends StatelessWidget {
  final bool loading;
  final String error;
  final List<DoctorDirectoryEntry> doctors;
  final String? selectedId;
  final VoidCallback onRetry;
  final ValueChanged<String> onSelect;
  final ValueChanged<DoctorDirectoryEntry> onViewProfile;

  const _DoctorStep({
    super.key,
    required this.loading,
    required this.error,
    required this.doctors,
    required this.selectedId,
    required this.onRetry,
    required this.onSelect,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (doctors.isEmpty) {
      return const EmptyListState(
        icon: Icons.medical_services_outlined,
        message:
            'No doctors found yet. Ask your clinic to create a doctor account first.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: doctors.length,
      separatorBuilder: (context, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final d = doctors[i];
        return DoctorSelectTile(
          doctor: d,
          selected: selectedId == d.id,
          onSelect: () => onSelect(d.id),
          onViewProfile: () => onViewProfile(d),
        );
      },
    );
  }
}

// ---------- Step 2: schedule ----------

class _ScheduleStep extends StatelessWidget {
  final DateTime? date;
  final TimeOfDay? time;
  final List<TimeOfDay> slots;
  final bool Function(TimeOfDay) isSlotDisabled;
  final String Function(DateTime) fmtDate;
  final String Function(TimeOfDay) fmtTime;
  final VoidCallback onPickDate;
  final ValueChanged<TimeOfDay> onPickSlot;

  const _ScheduleStep({
    super.key,
    required this.date,
    required this.time,
    required this.slots,
    required this.isSlotDisabled,
    required this.fmtDate,
    required this.fmtTime,
    required this.onPickDate,
    required this.onPickSlot,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        FormSectionCard(
          children: [
            const SectionLabel('Date', icon: Icons.calendar_today_outlined),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onPickDate,
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: Text(date == null ? 'Pick a date' : fmtDate(date!)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FormSectionCard(
          children: [
            const SectionLabel('Time slot',
                icon: Icons.access_time_outlined),
            Text(
              'Clinic hours 9 AM – 5 PM',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slot in slots)
                  ThemedChoiceChip(
                    label: fmtTime(slot),
                    isSelected: time?.hour == slot.hour &&
                        time?.minute == slot.minute,
                    onSelected: isSlotDisabled(slot)
                        ? null
                        : () => onPickSlot(slot),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ---------- Step 3: reason + review ----------

class _DetailsStep extends StatelessWidget {
  final DoctorDirectoryEntry? doctor;
  final String dateLabel;
  final String timeLabel;
  final TextEditingController reasonController;
  final ValueChanged<String> onChanged;

  const _DetailsStep({
    super.key,
    required this.doctor,
    required this.dateLabel,
    required this.timeLabel,
    required this.reasonController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        FormSectionCard(
          children: [
            const SectionLabel('Your visit',
                icon: Icons.receipt_long_outlined),
            _ReviewRow(
              icon: Icons.person_outline,
              label: 'Doctor',
              value: doctor == null
                  ? '—'
                  : doctor!.specialty.isEmpty
                      ? doctor!.name
                      : '${doctor!.name} · ${doctor!.specialty}',
            ),
            const Divider(),
            _ReviewRow(
              icon: Icons.calendar_month_outlined,
              label: 'When',
              value: '$dateLabel · $timeLabel',
            ),
          ],
        ),
        const SizedBox(height: 16),
        FormSectionCard(
          children: [
            const SectionLabel('Reason for visit',
                icon: Icons.notes_outlined),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText:
                    'Symptoms, concerns, or what you want checked…',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your doctor reviews each request and confirms it under Appointments.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.listTileTheme.iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Sticky Back / Continue bar ----------

class _StepBar extends StatelessWidget {
  final int step;
  final bool isLast;
  final bool isSaving;
  final bool canContinue;
  final String hint;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _StepBar({
    required this.step,
    required this.isLast,
    required this.isSaving,
    required this.canContinue,
    required this.hint,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hint.isNotEmpty && canContinue == false)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  hint,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            Row(
              children: [
                if (step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBack,
                      child: const Text('Back'),
                    ),
                  ),
                if (step > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed:
                        (canContinue && !isSaving) ? onNext : null,
                    child: isSaving
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary,
                            ),
                          )
                        : Text(isLast ? 'Send request' : 'Continue'),
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

// ---------- Success ----------

class _SuccessView extends StatelessWidget {
  final DoctorDirectoryEntry? doctor;
  final String dateLabel;
  final String timeLabel;

  const _SuccessView({
    required this.doctor,
    required this.dateLabel,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent =
        isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: accent,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Request sent',
          style: theme.textTheme.headlineMedium
              ?.copyWith(fontSize: 22),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${doctor?.name ?? 'Your doctor'} · $dateLabel · $timeLabel\n'
          'Track approval under My Care.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
