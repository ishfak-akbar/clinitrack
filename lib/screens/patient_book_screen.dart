import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../repositories/auth_repository.dart';
import '../widgets/app_scaffold.dart';
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

  List<({String id, String name, String specialty})> _doctors = [];
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
      setState(() {
        _doctors = rows;
        if (_selectedDoctorId == null && rows.isNotEmpty) {
          _selectedDoctorId = rows.first.id;
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
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
    if (_selectedDoctorId == null) {
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
    final displayName = auth.name.trim().isNotEmpty
        ? auth.name.trim()
        : myPatient.name;

    setState(() => _isSaving = true);
    final ok = await context.read<AppointmentProvider>().addAppointment(
          Appointment(
            id: '',
            patientId: myPatient.id,
            patientName: displayName,
            date: _fmtDate(_date!),
            dateIso: _iso(_date!),
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
                  const SectionLabel('Doctor', icon: Icons.medical_services_outlined),
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
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDoctorId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Choose doctor',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: _doctors
                          .map(
                            (d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(
                                d.specialty.isEmpty
                                    ? d.name
                                    : '${d.name} · ${d.specialty}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedDoctorId = v),
                      validator: (v) =>
                          v == null ? 'Please choose a doctor' : null,
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
