import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../repositories/auth_repository.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/doctor_card.dart';
import '../widgets/form_section_card.dart';
import '../widgets/section_label.dart';
import '../widgets/sticky_save_button.dart';

/// Part 5: patient books a `requested` appointment with a chosen doctor.
/// Sends `owner_id = doctor.id`, `patient_id = own linked row`.
class PatientBookScreen extends StatefulWidget {
  const PatientBookScreen({super.key});

  @override
  State<PatientBookScreen> createState() => _PatientBookScreenState();
}

class _PatientBookScreenState extends State<PatientBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _authRepo = AuthRepository();

  List<DoctorDirectoryEntry> _doctors = [];
  String? _selectedDoctorId;
  DateTime? _date;
  TimeOfDay? _time;
  bool _loadingDoctors = true;
  String _doctorsError = '';
  bool _isSaving = false;

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

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? start,
      firstDate: start,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDoctorId == null || _doctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a doctor')),
      );
      return;
    }
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a date and time')),
      );
      return;
    }

    final patientProvider = context.read<PatientProvider>();
    final myPatient = patientProvider.myLinked;
    if (myPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your patient profile is not linked yet. Pull to refresh on My Care and retry.',
          ),
        ),
      );
      return;
    }
    final doctor = _doctors.firstWhere(
      (d) => d.id == _selectedDoctorId,
      orElse: () => _doctors.first,
    );
    final auth = context.read<AuthProvider>();
    // Prefer the linked patient row name (source of truth for bookings);
    // fall back to the auth display name.
    final displayName = myPatient.name.trim().isNotEmpty
        ? myPatient.name.trim()
        : auth.name.trim();
    final iso = _iso(_date!);

    // Avoid duplicate active requests for the same doctor + day.
    final existing =
        context.read<AppointmentProvider>().appointments.where(
              (a) =>
                  a.doctor == doctor.name &&
                  a.dateIso == iso &&
                  (a.status == 'requested' || a.status == 'scheduled'),
            );
    if (existing.isNotEmpty) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request sent to doctor')),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AppScaffold(
        appBar: AppBar(title: const Text('Book visit')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              FormSectionCard(
                children: [
                  const SectionLabel('Choose your doctor',
                      icon: Icons.medical_services_outlined),
                  const SizedBox(height: 8),
                  if (_loadingDoctors)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_doctorsError.isNotEmpty)
                    Row(
                      children: [
                        Expanded(child: Text(_doctorsError)),
                        TextButton(
                          onPressed: _loadDoctors,
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  else if (_doctors.isEmpty)
                    const Text(
                      'No doctors found yet. Ask your clinic to create a doctor account first.',
                    )
                  else
                    Column(
                      children: [
                        for (final d in _doctors) ...[
                          DoctorCard(
                            doctor: d,
                            selected: _selectedDoctorId == d.id,
                            onSelect: () =>
                                setState(() => _selectedDoctorId = d.id),
                            onViewProfile: () =>
                                showDoctorProfileSheet(context, d),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_selectedDoctorId == null)
                          const Text(
                            'Please choose a doctor',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  const SectionLabel('Reason', icon: Icons.notes_outlined),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Fever, checkup, consultation...',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Reason is required'
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FormSectionCard(
                children: [
                  const SectionLabel('Date & Time',
                      icon: Icons.calendar_month_outlined),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined,
                              size: 18),
                          label: Text(
                            _date == null ? 'Date' : _fmtDate(_date!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon:
                              const Icon(Icons.access_time, size: 18),
                          label: Text(
                            _time == null ? 'Time' : _fmtTime(_time!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: StickySaveButton(
          isSaving: _isSaving,
          onPressed: _submit,
          label: 'Send request',
        ),
      ),
    );
  }
}
