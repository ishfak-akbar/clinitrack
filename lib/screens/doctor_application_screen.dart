import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/form_section_card.dart';
import '../widgets/section_label.dart';
import '../widgets/sticky_save_button.dart';

/// Step 2 of doctor onboarding: the professional-details application.
///
/// Opened once right after a doctor registers (patients never see it).
/// Saves into the verification columns from
/// `supabase/doctor_verification.sql`. Fresh signups are already `pending`
/// via the signup trigger — submitting here completes the application.
/// Gating to the pending screen lands in step 3; until then a submit
/// routes to the normal home route.

// ---------- Pure helpers (unit-tested in test/doctor_application_test.dart) ----------

/// Parses a graduation year, or returns null when out of range / not numeric.
int? parseGraduationYear(String input) {
  final year = int.tryParse(input.trim());
  if (year == null) return null;
  if (year < 1950 || year > DateTime.now().year) return null;
  return year;
}

/// Trims, drops empties and de-duplicates (case-insensitive, keeps first).
List<String> normalizeSpecialties(Iterable<String> input) {
  final seen = <String>{};
  final out = <String>[];
  for (final raw in input) {
    final s = raw.trim();
    if (s.isEmpty) continue;
    if (seen.add(s.toLowerCase())) out.add(s);
  }
  return out;
}

/// Demo placeholders shipped by AuthProvider for offline mode must never
/// look prefilled in a verification form — a doctor could submit a fake
/// license number without noticing. Blank them; real values pass through.
String blankDemoDefault(String value, String demoDefault) {
  return value.trim() == demoDefault ? '' : value;
}

/// Must match the demo defaults in AuthProvider.
abstract final class _Demo {
  static const licenseNumber = 'MBBS-214578';
  static const phone = '01912345678';
  static const qualifications = 'MBBS, FCPS (Medicine)';
  static const experienceYears = '5';
  static const clinicAddress = 'Zindabazar, Sylhet';
}

/// Common specialties offered in the dropdown (plus free-text Other).
const List<String> kSpecialtyOptions = [
  'General Physician',
  'Cardiology',
  'Pediatrics',
  'Orthopedics',
  'Dermatology',
  'Gynecology',
  'Neurology',
  'Ophthalmology',
  'ENT',
  'Psychiatry',
  'Surgery',
  'Dentistry',
];

/// Dropdown sentinel for the free-text option.
const String kOtherSpecialty = '__other__';

class DoctorApplicationScreen extends StatefulWidget {
  const DoctorApplicationScreen({super.key});

  @override
  State<DoctorApplicationScreen> createState() =>
      _DoctorApplicationScreenState();
}

class _DoctorApplicationScreenState extends State<DoctorApplicationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _chamberController;
  late final TextEditingController _clinicAddressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _titleController;
  late final TextEditingController _degreeController;
  late final TextEditingController _institutionController;
  late final TextEditingController _gradYearController;
  late final TextEditingController _licenseController;
  late final TextEditingController _experienceController;
  late final TextEditingController _qualificationsController;
  late final TextEditingController _bioController;
  late final TextEditingController _customSpecialtyController;
  late final FocusNode _customSpecialtyFocus;
  // Resets the dropdown back to its hint after every pick. Without this,
  // the field's internal value would keep the picked item while the
  // rebuilt menu excludes it (already selected) → dropdown assertion crash.
  final _specialtyDropdownKey = GlobalKey<FormFieldState<String>>();

  Set<String> _selectedSpecialties = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Prefill from whatever the profile already holds (resubmit path),
    // but blank the offline demo placeholders — they are not real data.
    final auth = context.read<AuthProvider>();
    _chamberController = TextEditingController(text: auth.chamberName);
    _clinicAddressController = TextEditingController(
      text: blankDemoDefault(auth.clinicAddress, _Demo.clinicAddress),
    );
    _phoneController = TextEditingController(
      text: blankDemoDefault(auth.phone, _Demo.phone),
    );
    _titleController = TextEditingController(text: auth.title);
    _degreeController = TextEditingController(text: auth.degree);
    _institutionController =
        TextEditingController(text: auth.graduatingInstitution);
    _gradYearController = TextEditingController(text: auth.graduationYear);
    _licenseController = TextEditingController(
      text: blankDemoDefault(auth.licenseNumber, _Demo.licenseNumber),
    );
    _experienceController = TextEditingController(
      text: blankDemoDefault(auth.experienceYears, _Demo.experienceYears),
    );
    _qualificationsController = TextEditingController(
      text: blankDemoDefault(auth.qualifications, _Demo.qualifications),
    );
    _bioController = TextEditingController(text: auth.bio);
    _customSpecialtyController = TextEditingController();
    _customSpecialtyFocus = FocusNode();
    // Seed from the stored array only — the single-line specialty may still
    // hold the demo default, which must not look like a real selection.
    _selectedSpecialties = normalizeSpecialties(auth.specialties).toSet();
  }

  @override
  void dispose() {
    _chamberController.dispose();
    _clinicAddressController.dispose();
    _phoneController.dispose();
    _titleController.dispose();
    _degreeController.dispose();
    _institutionController.dispose();
    _gradYearController.dispose();
    _licenseController.dispose();
    _experienceController.dispose();
    _qualificationsController.dispose();
    _bioController.dispose();
    _customSpecialtyController.dispose();
    _customSpecialtyFocus.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  String? _gradYearValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Graduation year is required';
    }
    if (parseGraduationYear(value) == null) {
      return 'Enter a valid year (1950–${DateTime.now().year})';
    }
    return null;
  }

  void _addSpecialty(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return;
    setState(() {
      _selectedSpecialties =
          normalizeSpecialties([..._selectedSpecialties, cleaned]).toSet();
    });
    _specialtyDropdownKey.currentState?.reset();
  }

  void _onDropdownChanged(String? value) {
    if (value == null) return;
    if (value == kOtherSpecialty) {
      _customSpecialtyFocus.requestFocus();
      return;
    }
    _addSpecialty(value);
  }

  void _addCustomSpecialty() {
    _addSpecialty(_customSpecialtyController.text);
    _customSpecialtyController.clear();
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final specialties = normalizeSpecialties(_selectedSpecialties);
    if (specialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one specialty'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    // A rejected doctor resubmitting moves back to pending (re-review).
    // The DB trigger permits users to set their own status to pending only.
    final resubmit = auth.verificationStatus == 'rejected';
    await auth.updateProfile(
      name: auth.name,
      specialty: specialties.first,
      licenseNumber: _licenseController.text.trim(),
      email: auth.email,
      phone: _phoneController.text.trim(),
      qualifications: _qualificationsController.text.trim(),
      experienceYears: _experienceController.text.trim(),
      clinicAddress: _clinicAddressController.text.trim(),
      bio: _bioController.text.trim(),
      chamberName: _chamberController.text.trim(),
      title: _titleController.text.trim(),
      degree: _degreeController.text.trim(),
      graduatingInstitution: _institutionController.text.trim(),
      graduationYear: _gradYearController.text.trim(),
      specialties: specialties,
      requestReReview: resubmit,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (auth.errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Application submitted for verification'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Step 3 will intercept pending doctors with the under-review screen.
    Navigator.of(context).pushReplacementNamed(auth.homeRoute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AppScaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Doctor verification'),
          actions: [
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout_outlined),
              onPressed: _isSaving ? null : _logout,
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Text(
                'Tell us about your practice. An admin reviews every '
                'application before your account is activated.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),

              // ---------- Practice ----------
              FormSectionCard(
                children: [
                  const SectionLabel('Practice',
                      icon: Icons.local_hospital_outlined),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _chamberController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Institution / Chamber name',
                      hintText: 'e.g. City Clinic, Zindabazar',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clinicAddressController,
                    textCapitalization: TextCapitalization.words,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Chamber location',
                      hintText: 'e.g. Zindabazar, Sylhet',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contact phone',
                      hintText: '01XXXXXXXXX',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: _required,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ---------- Credentials ----------
              FormSectionCard(
                children: [
                  const SectionLabel('Credentials',
                      icon: Icons.school_outlined),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Professional title',
                      hintText: 'e.g. Consultant, Surgeon, Dentist',
                      prefixIcon: Icon(Icons.assignment_ind_outlined),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _degreeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Degree',
                      hintText: 'e.g. MBBS',
                      prefixIcon: Icon(Icons.workspace_premium_outlined),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _institutionController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Institution graduated from',
                      hintText: 'e.g. Sylhet MAG Osmani Medical College',
                      prefixIcon:
                          Icon(Icons.account_balance_outlined),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _gradYearController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Graduation year',
                            hintText: 'e.g. 2018',
                            prefixIcon:
                                Icon(Icons.calendar_month_outlined),
                          ),
                          validator: _gradYearValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _experienceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Experience (yrs)',
                            hintText: 'e.g. 5',
                            prefixIcon:
                                Icon(Icons.work_history_outlined),
                          ),
                          validator: _required,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _licenseController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'License / BMDC number',
                      hintText: 'MBBS-XXXXXX',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _qualificationsController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Other qualifications',
                      hintText: 'e.g. FCPS (Medicine)',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ---------- Specialties ----------
              FormSectionCard(
                children: [
                  const SectionLabel('Specialties',
                      icon: Icons.medical_services_outlined),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: _specialtyDropdownKey,
                    initialValue: null,
                    hint: const Text('Choose a specialty to add'),
                    decoration: const InputDecoration(
                      prefixIcon:
                          Icon(Icons.add_circle_outline),
                    ),
                    items: [
                      for (final option in kSpecialtyOptions)
                        if (!_selectedSpecialties.contains(option))
                          DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                      const DropdownMenuItem(
                        value: kOtherSpecialty,
                        child: Text('Other…'),
                      ),
                    ],
                    onChanged: _onDropdownChanged,
                  ),
                  if (_selectedSpecialties.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in _selectedSpecialties)
                          InputChip(
                            label: Text(s),
                            onDeleted: () => setState(
                              () => _selectedSpecialties.remove(s),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customSpecialtyController,
                          focusNode: _customSpecialtyFocus,
                          textCapitalization: TextCapitalization.words,
                          onSubmitted: (_) => _addCustomSpecialty(),
                          decoration: const InputDecoration(
                            labelText: 'Other specialty',
                            hintText: 'e.g. Endocrinology',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Add specialty',
                        icon: const Icon(Icons.add),
                        onPressed: _addCustomSpecialty,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ---------- About ----------
              FormSectionCard(
                children: [
                  const SectionLabel('About (optional)',
                      icon: Icons.info_outline),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      hintText:
                          'A short introduction patients will see...',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: StickySaveButton(
          isSaving: _isSaving,
          onPressed: _handleSubmit,
          label: 'Submit for verification',
        ),
      ),
    );
  }
}
