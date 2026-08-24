import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/patient_provider.dart';
import '../widgets/section_label.dart';
import '../widgets/form_section_card.dart';
import '../widgets/themed_choice_chip.dart';
import '../widgets/sticky_save_button.dart';

enum Gender { male, female, other }
enum BloodGroup { aPos, aNeg, bPos, bNeg, abPos, abNeg, oPos, oNeg }

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _historyController = TextEditingController();

  Gender _gender = Gender.male;
  BloodGroup _bloodGroup = BloodGroup.oPos;
  bool _isSaving = false;

  final Set<String> _allergies = {};
  final List<String> _allergyOptions = ['Milk', 'Peanuts', 'Latex', 'Dust', 'Others', 'None'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final genderLabel = switch (_gender) {
      Gender.male => 'Male',
      Gender.female => 'Female',
      Gender.other => 'Other',
    };

    final bloodGroupLabel = switch (_bloodGroup) {
      BloodGroup.aPos => 'A+',
      BloodGroup.aNeg => 'A-',
      BloodGroup.bPos => 'B+',
      BloodGroup.bNeg => 'B-',
      BloodGroup.abPos => 'AB+',
      BloodGroup.abNeg => 'AB-',
      BloodGroup.oPos => 'O+',
      BloodGroup.oNeg => 'O-',
    };

    final patient = Patient(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      age: _ageController.text.trim(),
      gender: genderLabel,
      contact: _contactController.text.trim(),
      bloodGroup: bloodGroupLabel,
      medicalHistory: _historyController.text.trim(),
      allergies: _allergies.toList(),
      lastVisit: 'Just added',
    );

    await context.read<PatientProvider>().addPatient(patient);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${patient.name} saved successfully'),
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
          title: const Text('Add Patient'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // ---------- Basic Info Card ----------
              FormSectionCard(
                children: [
                  const SectionLabel('Basic Information', icon: Icons.person_outline),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter patient name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age',
                            hintText: '28',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                          validator: _requiredValidator,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _contactController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact Number',
                            hintText: '01XXXXXXXXX',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: _requiredValidator,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------- Gender & Blood Group ----------
              FormSectionCard(
                children: [
                  const SectionLabel('Gender', icon: Icons.wc_outlined),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ThemedChoiceChip(
                        label: 'Male',
                        isSelected: _gender == Gender.male,
                        onSelected: () => setState(() => _gender = Gender.male),
                      ),
                      ThemedChoiceChip(
                        label: 'Female',
                        isSelected: _gender == Gender.female,
                        onSelected: () => setState(() => _gender = Gender.female),
                      ),
                      ThemedChoiceChip(
                        label: 'Other',
                        isSelected: _gender == Gender.other,
                        onSelected: () => setState(() => _gender = Gender.other),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SectionLabel('Blood Group', icon: Icons.bloodtype_outlined),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ThemedChoiceChip(
                        label: 'A+',
                        isSelected: _bloodGroup == BloodGroup.aPos,
                        onSelected: () => setState(() => _bloodGroup = BloodGroup.aPos),
                      ),
                      ThemedChoiceChip(
                        label: 'A-',
                        isSelected: _bloodGroup == BloodGroup.aNeg,
                        onSelected: () => setState(() => _bloodGroup = BloodGroup.aNeg),
                      ),
                      ThemedChoiceChip(
                        label: 'B+',
                        isSelected: _bloodGroup == BloodGroup.bPos,
                        onSelected: () => setState(() => _bloodGroup = BloodGroup.bPos),
                      ),
                      ThemedChoiceChip(
                        label: 'B-',
                        isSelected: _bloodGroup == BloodGroup.bNeg,
                        onSelected: () => setState(() => _bloodGroup = BloodGroup.bNeg),
                      ),
                      ThemedChoiceChip(
                        label: 'O+',
                        isSelected: _bloodGroup == BloodGroup.oPos,
                        onSelected: () => setState(() => _bloodGroup = BloodGroup.oPos),
                      ),
                      ThemedChoiceChip(
                        label: 'O-',
                        isSelected: _bloodGroup == BloodGroup.oNeg,
                        onSelected: () => setState(() => _bloodGroup = BloodGroup.oNeg),
                      ),
                      ThemedChoiceChip(
                        label: 'AB+',
                        isSelected: _bloodGroup == BloodGroup.abPos,
                        onSelected: () => setState(() => _bloodGroup = BloodGroup.abPos),
                      ),
                      ThemedChoiceChip(
                        label: 'AB-',
                        isSelected: _bloodGroup == BloodGroup.abNeg,
                        onSelected: () => setState(() => _bloodGroup = BloodGroup.abNeg),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------- Medical History ----------
              FormSectionCard(
                children: [
                  const SectionLabel('Medical History', icon: Icons.medical_information_outlined),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _historyController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Previous illnesses, surgeries, chronic conditions...',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------- Allergies ----------
              FormSectionCard(
                children: [
                  const SectionLabel('Allergies', icon: Icons.warning_amber_rounded),
                  const SizedBox(height: 8),

                  Builder(builder: (context) {
                    final theme = Theme.of(context);
                    final isDark = theme.brightness == Brightness.dark;
                    return InkWell(
                      onTap: _showAllergiesPicker,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? AppColors.darkCard : Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_drop_down, color: theme.textTheme.bodySmall?.color),
                            const SizedBox(width: 8),
                            Text(
                              _allergies.isEmpty ? 'Select allergies' : '${_allergies.length} selected',
                              style: TextStyle(
                                color: _allergies.isEmpty
                                    ? theme.textTheme.bodySmall?.color
                                    : theme.textTheme.bodyLarge?.color,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  if (_allergies.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allergies.map((allergy) {
                        final accent = Theme.of(context).brightness == Brightness.dark
                            ? AppColors.primaryTealAccent
                            : AppColors.primaryTeal;
                        return Chip(
                          label: Text(allergy, style: const TextStyle(fontSize: 13)),
                          backgroundColor: accent.withValues(alpha: 0.12),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() => _allergies.remove(allergy));
                          },
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // ---------- Sticky Save Button ----------
        bottomNavigationBar: StickySaveButton(
          isSaving: _isSaving,
          onPressed: _handleSave,
          label: 'Save Patient',
        ),
      ),
    );
  }

  void _showAllergiesPicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Allergies',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _allergyOptions.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 3.2,
                    ),
                    itemBuilder: (context, index) {
                      final allergy = _allergyOptions[index];
                      final isSelected = _allergies.contains(allergy);

                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              _allergies.remove(allergy);
                            } else {
                              _allergies.add(allergy);
                            }
                          });
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent.withValues(alpha: 0.12)
                                : (isDark ? AppColors.darkBackground : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? accent : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_box_rounded
                                    : Icons.check_box_outline_blank_rounded,
                                size: 20,
                                color: isSelected ? accent : theme.textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  allergy,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? accent : theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Done Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}