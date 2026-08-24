import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../widgets/section_label.dart';
import '../providers/appointment_provider.dart';

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
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
    _patientNameController.dispose();
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

    setState(() => _isSaving = true);

    final appointment = Appointment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientName: _patientNameController.text.trim(),
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
        backgroundColor: AppColors.screenTintedBackground,
        appBar: AppBar(
          backgroundColor: AppColors.screenTintedBackground,
          elevation: 0,
          title: const Text('Add Appointment'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // ---------- Patient & Reason ----------
              _buildCard(
                children: [
                  const SectionLabel('Patient Name', icon: Icons.person_outline),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _patientNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Enter patient name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Patient name is required' : null,
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
              _buildCard(
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
              _buildCard(
                children: [
                  const SectionLabel('Select Doctor', icon: Icons.medical_services_outlined),
                  const SizedBox(height: 12),
                  Column(
                    children: List.generate(_doctors.length, (index) {
                      final isSelected = _selectedDoctorIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => setState(() => _selectedDoctorIndex = index),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryTeal.withOpacity(0.08) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryTeal : Colors.grey.shade300,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isSelected ? AppColors.primaryTeal : Colors.grey.shade300,
                                  child: Text(
                                    _doctors[index].split(' ').last[0],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black54,
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
                                      color: isSelected ? AppColors.primaryTeal : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: AppColors.primaryTeal, size: 22),
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
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
                    : const Text(
                  'Schedule Appointment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Helper Widgets ----------

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildPickerField({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.primaryTeal.withOpacity(0.05) : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.primaryTeal : Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? AppColors.primaryTeal : Colors.grey.shade600,
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