import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/section_label.dart';
import '../widgets/form_section_card.dart';
import '../widgets/themed_choice_chip.dart';
import '../widgets/sticky_save_button.dart';

enum PrescriptionFrequency { daily, twiceADay, weekly }

class AddPrescriptionScreen extends StatefulWidget {
  const AddPrescriptionScreen({super.key});

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientController = TextEditingController(text: 'Nahian');
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

    await Future.delayed(const Duration(seconds: 1)); // simulate save

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prescription saved successfully'),
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
          title: const Text('Add Prescription'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // ---------- Patient ----------
              FormSectionCard(
                children: [
                  const SectionLabel('Patient', icon: Icons.person_outline),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _patientController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------- Medicine Info ----------
              FormSectionCard(
                children: [
                  const SectionLabel('Medicine Details', icon: Icons.medication_outlined),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _medicineController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Medicine Name',
                      hintText: 'Paracetamol',
                      prefixIcon: Icon(Icons.medication_outlined),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dosageController,
                          decoration: const InputDecoration(
                            labelText: 'Dosage',
                            hintText: '500mg',
                            prefixIcon: Icon(Icons.science_outlined),
                          ),
                          validator: _requiredValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          decoration: const InputDecoration(
                            labelText: 'Duration',
                            hintText: '5 Days',
                            prefixIcon: Icon(Icons.timelapse_outlined),
                          ),
                          validator: _requiredValidator,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------- Frequency ----------
              FormSectionCard(
                children: [
                  const SectionLabel('Frequency', icon: Icons.repeat),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ThemedChoiceChip(
                        label: 'Daily',
                        isSelected: _frequency == PrescriptionFrequency.daily,
                        onSelected: () => setState(() => _frequency = PrescriptionFrequency.daily),
                      ),
                      ThemedChoiceChip(
                        label: 'Twice a day',
                        isSelected: _frequency == PrescriptionFrequency.twiceADay,
                        onSelected: () => setState(() => _frequency = PrescriptionFrequency.twiceADay),
                      ),
                      ThemedChoiceChip(
                        label: 'Weekly',
                        isSelected: _frequency == PrescriptionFrequency.weekly,
                        onSelected: () => setState(() => _frequency = PrescriptionFrequency.weekly),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------- Notes ----------
              FormSectionCard(
                children: [
                  const SectionLabel('Notes', icon: Icons.notes_outlined),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'After meal, before sleep, etc.',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ---------- Sticky Save Button ----------
        bottomNavigationBar: StickySaveButton(
          isSaving: _isSaving,
          onPressed: _handleSave,
          label: 'Save Prescription',
        ),
      ),
    );
  }
}