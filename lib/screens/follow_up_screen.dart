import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../widgets/section_label.dart';
import '../providers/patient_provider.dart';
import '../providers/follow_up_provider.dart';

class FollowUpScreen extends StatefulWidget {
  const FollowUpScreen({super.key});

  @override
  State<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientController = TextEditingController();
  final _notesController = TextEditingController();

  Patient? _patient;
  bool _needFollowUp = true;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_patient == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Patient) {
        _patient = args;
        _patientController.text = args.name;
      } else if (args is String && args.isNotEmpty) {
        _patientController.text = args;
      }
    }
  }

  @override
  void dispose() {
    _patientController.dispose();
    _notesController.dispose();
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

  String _formatDate(DateTime date) => FollowUp.formatDisplayDate(date);

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _toIsoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_needFollowUp) {
      Navigator.of(context).pop();
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a follow-up date')),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a follow-up time')),
      );
      return;
    }
    final patientName = _patientController.text.trim();
    if (patientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No patient selected')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final followUp = FollowUp(
      id: '',
      patientId: _patient?.id,
      patientName: patientName,
      dateIso: _toIsoDate(_selectedDate!),
      dateLabel: _formatDate(_selectedDate!),
      time: _formatTime(_selectedTime!),
      notes: _notesController.text.trim(),
    );

    final ok = await context.read<FollowUpProvider>().addFollowUp(followUp);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context
                  .read<FollowUpProvider>()
                  .errorMessage
                  .isEmpty
              ? 'Could not save follow-up'
              : context.read<FollowUpProvider>().errorMessage),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder saved successfully')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Follow-up')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionLabel('Patient'),
            TextFormField(
              controller: _patientController,
              readOnly: true,
              decoration: const InputDecoration(hintText: 'Select patient'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'No patient selected' : null,
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              value: _needFollowUp,
              title: const Text('Need Follow-up?'),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) => setState(() => _needFollowUp = value),
            ),
            const SizedBox(height: 8),

            if (_needFollowUp) ...[
              const SectionLabel('Follow-up Date'),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: _selectedDate == null ? '' : _formatDate(_selectedDate!),
                    ),
                    decoration: const InputDecoration(
                      hintText: '25 May 2025',
                      suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const SectionLabel('Follow-up Time'),
              GestureDetector(
                onTap: _pickTime,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: _selectedTime == null ? '' : _formatTime(_selectedTime!),
                    ),
                    decoration: const InputDecoration(
                      hintText: '11:00 AM',
                      suffixIcon: Icon(Icons.access_time, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SectionLabel('Notes'),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Recheck after 5 days'),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.cardWhite),
              )
                  : const Text('Save Reminder'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
