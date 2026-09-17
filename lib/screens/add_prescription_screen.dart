import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import '../widgets/section_label.dart';
import '../widgets/form_section_card.dart';
import '../widgets/themed_choice_chip.dart';
import '../widgets/sticky_save_button.dart';
import 'package:provider/provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/patient_provider.dart';

enum PrescriptionFrequency { daily, twiceADay, weekly }

class AddPrescriptionScreen extends StatefulWidget {
  const AddPrescriptionScreen({super.key});

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientController = TextEditingController();
  Patient? _patient;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_patient == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Patient) {
        _patient = args;
        _patientController.text = args.name;
      }
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No patient selected'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isSaving = true);

    final frequencyLabel = switch (_frequency) {
      PrescriptionFrequency.daily => 'Daily',
      PrescriptionFrequency.twiceADay => 'Twice a day',
      PrescriptionFrequency.weekly => 'Weekly',
    };

    final prescription = Prescription(
      id: '',
      patientId: _patient!.id,
      medicineName: _medicineController.text.trim(),
      dosage: _dosageController.text.trim(),
      duration: _durationController.text.trim(),
      frequency: frequencyLabel,
      notes: _notesController.text.trim(),
    );

    final ok =
        await context.read<PrescriptionProvider>().addPrescription(prescription);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context
                  .read<PrescriptionProvider>()
                  .errorMessage
                  .isEmpty
              ? 'Could not save prescription'
              : context.read<PrescriptionProvider>().errorMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
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
      child: AppScaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text('Add Prescription'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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