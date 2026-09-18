import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/patient_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/form_section_card.dart';
import '../widgets/section_label.dart';
import '../widgets/sticky_save_button.dart';

/// Part 5: patient edits own linked demographics.
class PatientEditScreen extends StatefulWidget {
  const PatientEditScreen({super.key});

  @override
  State<PatientEditScreen> createState() => _PatientEditScreenState();
}

class _PatientEditScreenState extends State<PatientEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _contact;
  late final TextEditingController _history;
  late final TextEditingController _allergies;
  String _gender = '';
  String _bloodGroup = '';
  bool _isSaving = false;
  bool _loaded = false;

  static const _genders = ['Male', 'Female', 'Other'];
  static const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _age = TextEditingController();
    _contact = TextEditingController();
    _history = TextEditingController();
    _allergies = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fill());
  }

  Future<void> _fill() async {
    final provider = context.read<PatientProvider>();
    await provider.loadPatients();
    await provider.fetchMyLinked();
    if (!mounted) return;
    final me = provider.myLinked;
    if (me != null) {
      _name.text = me.name;
      _age.text = me.age;
      _contact.text = me.contact;
      _history.text = me.medicalHistory;
      _allergies.text = me.allergies.join(', ');
      setState(() {
        _gender = me.gender;
        _bloodGroup = me.bloodGroup;
        _loaded = true;
      });
    } else {
      setState(() => _loaded = true);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _contact.dispose();
    _history.dispose();
    _allergies.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final ok = await context.read<PatientProvider>().updateMyLinked(
          name: _name.text,
          age: _age.text,
          gender: _gender,
          contact: _contact.text,
          bloodGroup: _bloodGroup,
          medicalHistory: _history.text,
          allergies: _allergies.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context
                  .read<PatientProvider>()
                  .errorMessage
                  .isEmpty
              ? 'Could not save'
              : context.read<PatientProvider>().errorMessage),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Health profile updated')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<PatientProvider>().myLinked;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AppScaffold(
        appBar: AppBar(title: const Text('Edit health profile')),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : me == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Your patient profile is not linked yet. Pull to refresh on My Care and retry.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        FormSectionCard(
                          children: [
                            const SectionLabel('Basic',
                                icon: Icons.person_outline),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _name,
                              decoration: const InputDecoration(
                                  labelText: 'Full name'),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Name is required'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _age,
                                    keyboardType:
                                        TextInputType.number,
                                    decoration:
                                        const InputDecoration(
                                            labelText: 'Age'),
                                    validator: (v) {
                                      if (v == null ||
                                          v.trim().isEmpty) {
                                        return null;
                                      }
                                      final n = int.tryParse(
                                          v.trim());
                                      if (n == null ||
                                          n < 0 ||
                                          n > 130) {
                                        return '0–130';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child:
                                      DropdownButtonFormField<
                                          String>(
                                    initialValue: _gender.isEmpty
                                        ? null
                                        : _gender,
                                    decoration:
                                        const InputDecoration(
                                            labelText: 'Gender'),
                                    items: _genders
                                        .map((g) =>
                                            DropdownMenuItem(
                                              value: g,
                                              child: Text(g),
                                            ))
                                        .toList(),
                                    onChanged: (v) => setState(
                                        () => _gender = v ?? ''),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _contact,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                  labelText: 'Contact'),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue:
                                  _bloodGroup.isEmpty
                                      ? null
                                      : _bloodGroup,
                              decoration: const InputDecoration(
                                  labelText: 'Blood group'),
                              items: _bloodGroups
                                  .map((b) => DropdownMenuItem(
                                        value: b,
                                        child: Text(b),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(
                                  () => _bloodGroup = v ?? ''),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FormSectionCard(
                          children: [
                            const SectionLabel('Health',
                                icon: Icons.notes_outlined),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _history,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Medical history',
                                hintText:
                                    'Conditions, surgeries...',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _allergies,
                              decoration: const InputDecoration(
                                labelText: 'Allergies',
                                hintText:
                                    'Comma separated, e.g. Penicillin, Dust',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
        bottomNavigationBar: StickySaveButton(
          isSaving: _isSaving,
          onPressed: _save,
          label: 'Save changes',
        ),
      ),
    );
  }
}
