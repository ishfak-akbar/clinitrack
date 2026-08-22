import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/section_label.dart';

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
  final List<String> _allergyOptions = ['Penicillin', 'Peanuts', 'Latex', 'None'];

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
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_nameController.text} saved successfully')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.screenTintedBackground,
      appBar: AppBar(backgroundColor: AppColors.screenTintedBackground,title: const Text('Add Patient')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionLabel('Patient Name'),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'John Doe'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('Age'),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '28'),
                        validator: _requiredValidator,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('Gender'),
                      Wrap(
                        spacing: 4,
                        children: [
                          _genderRadio('Male', Gender.male),
                          _genderRadio('Female', Gender.female),
                          _genderRadio('Other', Gender.other),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            const SectionLabel('Contact'),
            TextFormField(
              controller: _contactController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '01912345678'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 16),

            const SectionLabel('Blood Group'),
            Wrap(
              spacing: 4,
              runSpacing: 0,
              children: [
                _bloodGroupRadio('A+', BloodGroup.aPos),
                _bloodGroupRadio('A-', BloodGroup.aNeg),
                _bloodGroupRadio('B+', BloodGroup.bPos),
                _bloodGroupRadio('B-', BloodGroup.bNeg),
                _bloodGroupRadio('O+', BloodGroup.oPos),
                _bloodGroupRadio('O-', BloodGroup.oNeg),
                _bloodGroupRadio('AB+', BloodGroup.abPos),
                _bloodGroupRadio('AB-', BloodGroup.abNeg),
              ],
            ),
            const SizedBox(height: 12),

            const SectionLabel('Medical History'),
            TextFormField(
              controller: _historyController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'No major illnesses in the past.'),
            ),
            const SizedBox(height: 16),

            const SectionLabel('Allergies'),
            ..._allergyOptions.map((allergy) {
              return CheckboxListTile(
                value: _allergies.contains(allergy),
                title: Text(allergy),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _allergies.add(allergy);
                    } else {
                      _allergies.remove(allergy);
                    }
                  });
                },
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
                  : const Text('Save Patient'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _genderRadio(String label, Gender value) {
    return SizedBox(
      width: 100,
      child: RadioListTile<Gender>(
        value: value,
        groupValue: _gender,
        title: Text(label, style: const TextStyle(fontSize: 13)),
        contentPadding: EdgeInsets.zero,
        dense: true,
        onChanged: (v) => setState(() => _gender = v!),
      ),
    );
  }

  Widget _bloodGroupRadio(String label, BloodGroup value) {
    return SizedBox(
      width: 90,
      child: RadioListTile<BloodGroup>(
        value: value,
        groupValue: _bloodGroup,
        title: Text(label, style: const TextStyle(fontSize: 13)),
        contentPadding: EdgeInsets.zero,
        dense: true,
        onChanged: (v) => setState(() => _bloodGroup = v!),
      ),
    );
  }
}