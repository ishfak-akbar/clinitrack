import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/section_label.dart';

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _selectedDoctorIndex = 0;
  bool _isSaving = false;

  final List<String> _doctors = ['Dr. Sarah Ahmed', 'Dr. James Wilson', 'Dr. Emily Clark', 'Dr. Michael Brown'];

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
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment scheduled successfully')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.screenTintedBackground,
      appBar: AppBar(backgroundColor: AppColors.screenTintedBackground,title: const Text('Appointment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionLabel('Select Date'),
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: TextFormField(
                  controller: TextEditingController(
                    text: _selectedDate == null ? '' : _formatDate(_selectedDate!),
                  ),
                  decoration: const InputDecoration(
                    hintText: '20 May 2025',
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const SectionLabel('Select Time'),
            GestureDetector(
              onTap: _pickTime,
              child: AbsorbPointer(
                child: TextFormField(
                  controller: TextEditingController(
                    text: _selectedTime == null ? '' : _formatTime(_selectedTime!),
                  ),
                  decoration: const InputDecoration(
                    hintText: '10:30 AM',
                    suffixIcon: Icon(Icons.access_time, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const SectionLabel('Reason'),
            TextFormField(
              controller: _reasonController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Regular checkup and consultation'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Reason is required' : null,
            ),
            const SizedBox(height: 16),

            const SectionLabel('Select Doctor'),
            ...List.generate(_doctors.length, (index) {
              return RadioListTile<int>(
                value: index,
                groupValue: _selectedDoctorIndex,
                title: Text(_doctors[index]),
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => setState(() => _selectedDoctorIndex = value!),
              );
            }),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.cardWhite),
              )
                  : const Text('Schedule Appointment'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}