import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/section_label.dart';

enum PrescriptionFrequency { daily, twiceADay, weekly }

class AddPrescriptionScreen extends StatefulWidget {
  const AddPrescriptionScreen({super.key});

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientController = TextEditingController(text: 'John Doe');
  final _medicineController = TextEditingController();
  final _dosageController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  PrescriptionFrequency _frequency = PrescriptionFrequency.daily;
  bool _isSaving = false;

  @override
  void dispose() {
    _patientController.dispose();
    _medicineController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prescription saved successfully')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prescription')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionLabel('Patient'),
            TextFormField(
              controller: _patientController,
              readOnly: true,
              decoration: const InputDecoration(hintText: 'John Doe'),
            ),
            const SizedBox(height: 16),

            const SectionLabel('Medicine Name'),
            TextFormField(
              controller: _medicineController,
              decoration: const InputDecoration(hintText: 'Paracetamol'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 16),

            const SectionLabel('Dosage'),
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(hintText: '500mg'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 16),

            const SectionLabel('Frequency'),
            RadioListTile<PrescriptionFrequency>(
              value: PrescriptionFrequency.daily,
              groupValue: _frequency,
              title: const Text('Daily'),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) => setState(() => _frequency = value!),
            ),
            RadioListTile<PrescriptionFrequency>(
              value: PrescriptionFrequency.twiceADay,
              groupValue: _frequency,
              title: const Text('Twice a day'),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) => setState(() => _frequency = value!),
            ),
            RadioListTile<PrescriptionFrequency>(
              value: PrescriptionFrequency.weekly,
              groupValue: _frequency,
              title: const Text('Weekly'),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) => setState(() => _frequency = value!),
            ),
            const SizedBox(height: 8),

            const SectionLabel('Duration'),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(hintText: '5 Days'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 16),

            const SectionLabel('Notes'),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'After meal'),
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
                  : const Text('Save Prescription'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}