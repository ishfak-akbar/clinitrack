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
        backgroundColor: AppColors.screenTintedBackground,
        appBar: AppBar(
          backgroundColor: AppColors.screenTintedBackground,
          elevation: 0,
          title: const Text('Add Prescription'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // ---------- Patient ----------
              _buildCard(
                children: [
                  const SectionLabel('Patient', icon: Icons.person_outline),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _patientController,
                    readOnly: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------- Medicine Info ----------
              _buildCard(
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
              _buildCard(
                children: [
                  const SectionLabel('Frequency', icon: Icons.repeat),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFrequencyChip('Daily', PrescriptionFrequency.daily),
                      _buildFrequencyChip('Twice a day', PrescriptionFrequency.twiceADay),
                      _buildFrequencyChip('Weekly', PrescriptionFrequency.weekly),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------- Notes ----------
              _buildCard(
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
                  'Save Prescription',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Helpers ----------

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

  Widget _buildFrequencyChip(String label, PrescriptionFrequency value) {
    final isSelected = _frequency == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _frequency = value),
      selectedColor: AppColors.primaryTeal.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryTeal : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}