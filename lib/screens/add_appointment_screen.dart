import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../widgets/section_label.dart';
import '../widgets/form_section_card.dart';
import '../widgets/sticky_save_button.dart';
import '../providers/appointment_provider.dart';
import '../providers/patient_provider.dart';

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  Patient? _selectedPatient;
  final _reasonController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _selectedDoctorIndex = 0;
  bool _isSaving = false;

  final List<String> _doctors = [
    'Dr. Faiza Akter Borsha',
    'Dr. Ishrak Saleh Chowdhury',
    'Dr. Tasnia Akther',
    'Dr. Shakif Niaz',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isSaving = true);

    final appointment = Appointment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: _selectedPatient!.id,
      patientName: _selectedPatient!.name,
      date: _formatDate(_selectedDate!),
      time: _formatTime(_selectedTime!),
      reason: _reasonController.text.trim(),
      doctor: _doctors[_selectedDoctorIndex],
      status: 'scheduled',
    );

    await context.read<AppointmentProvider>().addAppointment(appointment);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appointment scheduled successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text('Add Appointment'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // ---------- Patient & Reason ----------
              FormSectionCard(
                children: [
                  const SectionLabel('Patient', icon: Icons.person_outline),
                  const SizedBox(height: 8),
                  Consumer<PatientProvider>(
                    builder: (context, patientProvider, _) {
                      final patients = patientProvider.patients;
                      return DropdownButtonFormField<Patient>(
                        initialValue: _selectedPatient,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: 'Select patient',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: patients
                            .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text('${p.name} (${p.age} yrs, ${p.gender})', overflow: TextOverflow.ellipsis),
                        ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedPatient = value),
                        validator: (value) => value == null ? 'Please select a patient' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel('Reason', icon: Icons.notes_outlined),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Regular checkup, consultation, follow-up...',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Reason is required' : null,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------- Date & Time ----------
              FormSectionCard(
                children: [
                  const SectionLabel('Date & Time', icon: Icons.calendar_month_outlined),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPickerField(
                          label: _selectedDate == null ? 'Select Date' : _formatDate(_selectedDate!),
                          icon: Icons.calendar_today_outlined,
                          onTap: _pickDate,
                          isSelected: _selectedDate != null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPickerField(
                          label: _selectedTime == null ? 'Select Time' : _formatTime(_selectedTime!),
                          icon: Icons.access_time,
                          onTap: _pickTime,
                          isSelected: _selectedTime != null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------- Select Doctor ----------
              FormSectionCard(
                children: [
                  const SectionLabel('Select Doctor', icon: Icons.medical_services_outlined),
                  const SizedBox(height: 12),
                  Column(
                    children: List.generate(_doctors.length, (index) {
                      final isSelected = _selectedDoctorIndex == index;
                      final theme = Theme.of(context);
                      final isDark = theme.brightness == Brightness.dark;
                      final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => setState(() => _selectedDoctorIndex = index),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accent.withValues(alpha: 0.08)
                                  : (isDark ? AppColors.darkCard : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? accent : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                  isSelected ? accent : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                                  child: Text(
                                    _doctors[index].split(' ').last[0],
                                    style: TextStyle(
                                      color: isSelected
                                          ? (isDark ? AppColors.darkBackground : Colors.white)
                                          : theme.textTheme.bodyMedium?.color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _doctors[index],
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: isSelected ? accent : theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle, color: accent, size: 22),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  )
                ],
              ),
            ],
          ),
        ),

        // ---------- Sticky Save Button ----------
        bottomNavigationBar: StickySaveButton(
          isSaving: _isSaving,
          onPressed: _handleSave,
          label: 'Schedule Appointment',
        ),
      ),
    );
  }

  // ---------- Helper Widgets ----------

  Widget _buildPickerField({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? accent : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? accent.withValues(alpha: 0.08)
              : (isDark ? AppColors.darkCard : Colors.grey.shade50),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? accent : theme.textTheme.bodySmall?.color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? accent : theme.textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}