import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/section_label.dart';
import '../widgets/form_section_card.dart';
import '../widgets/sticky_save_button.dart';
import '../widgets/user_avatar.dart';
import 'doctor_application_screen.dart'
    show normalizeSpecialties, parseGraduationYear;

/// Step 6: true when any *credential* field differs from the stored profile
/// (specialties compared order-insensitively). Free fields — name, contact,
/// chamber/location, bio, experience tenure — never trigger re-review.
bool doctorCredentialsChanged({
  required List<String> values,
  required List<String> stored,
  required List<String> specialties,
  required List<String> storedSpecialties,
}) {
  if (values.length != stored.length) return true;
  for (var i = 0; i < values.length; i++) {
    if (values[i].trim() != stored[i].trim()) return true;
  }
  final current =
      normalizeSpecialties(specialties).map((s) => s.toLowerCase()).toSet();
  final previous = normalizeSpecialties(storedSpecialties)
      .map((s) => s.toLowerCase())
      .toSet();
  return current.length != previous.length || !current.containsAll(previous);
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _licenseController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _qualificationsController;
  late final TextEditingController _experienceController;
  late final TextEditingController _clinicAddressController;
  late final TextEditingController _chamberController;
  late final TextEditingController _titleController;
  late final TextEditingController _degreeController;
  late final TextEditingController _institutionController;
  late final TextEditingController _gradYearController;
  late final TextEditingController _specialtiesController;
  late final TextEditingController _bioController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController = TextEditingController(text: auth.name);
    _specialtyController = TextEditingController(text: auth.specialty);
    _licenseController = TextEditingController(text: auth.licenseNumber);
    _emailController = TextEditingController(text: auth.email);
    _phoneController = TextEditingController(text: auth.phone);
    _qualificationsController = TextEditingController(text: auth.qualifications);
    _experienceController = TextEditingController(text: auth.experienceYears);
    _clinicAddressController = TextEditingController(text: auth.clinicAddress);
    _chamberController = TextEditingController(text: auth.chamberName);
    _titleController = TextEditingController(text: auth.title);
    _degreeController = TextEditingController(text: auth.degree);
    _institutionController =
        TextEditingController(text: auth.graduatingInstitution);
    _gradYearController = TextEditingController(text: auth.graduationYear);
    _specialtiesController =
        TextEditingController(text: auth.specialties.join(', '));
    _bioController = TextEditingController(text: auth.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _licenseController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _qualificationsController.dispose();
    _experienceController.dispose();
    _clinicAddressController.dispose();
    _chamberController.dispose();
    _titleController.dispose();
    _degreeController.dispose();
    _institutionController.dispose();
    _gradYearController.dispose();
    _specialtiesController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    final emailRegex = RegExp(r'^[\w\.\-+]+@[\w\-]+\.[\w\-.]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
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

  String? _specialtiesValidator(String? value) {
    if (value == null ||
        normalizeSpecialties(value.split(',')).isEmpty) {
      return 'Add at least one specialty';
    }
    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    final newSpecialties =
        normalizeSpecialties(_specialtiesController.text.split(','));
    // Credential edits on an approved account send it back for re-review
    // (the DB trigger permits users to set their own status to pending).
    final reReview = auth.verificationStatus == 'approved' &&
        doctorCredentialsChanged(
          values: [
            _titleController.text,
            _degreeController.text,
            _institutionController.text,
            _gradYearController.text,
            _licenseController.text,
            _qualificationsController.text,
            _specialtyController.text,
          ],
          stored: [
            auth.title,
            auth.degree,
            auth.graduatingInstitution,
            auth.graduationYear,
            auth.licenseNumber,
            auth.qualifications,
            auth.specialty,
          ],
          specialties: newSpecialties,
          storedSpecialties: auth.specialties,
        );

    await auth.updateProfile(
      name: _nameController.text.trim(),
      specialty: newSpecialties.isNotEmpty
          ? newSpecialties.first
          : _specialtyController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      email: _emailController.text.trim(),
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
      specialties: newSpecialties,
      requestReReview: reReview,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reReview
            ? 'Profile updated — sent for re-review'
            : 'Profile updated successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (reReview) {
      // The gate confines unapproved doctors to the waiting room.
      Navigator.of(context).pushReplacementNamed('/verification-pending');
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AppScaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text('Edit Profile'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              Center(
                child: Builder(
                  builder: (context) {
                    final auth = context.watch<AuthProvider>();
                    return UserAvatar(
                      avatarUrl: auth.avatarUrl,
                      name: _nameController.text.isEmpty
                          ? auth.name
                          : _nameController.text,
                      radius: 48,
                      editable: true,
                      onTap: () => pickAndSaveAvatar(context),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              FormSectionCard(
                children: [
                  const SectionLabel('Basic Information', icon: Icons.person_outline),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Dr. Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _specialtyController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Specialty',
                      hintText: 'e.g. General Physician',
                      prefixIcon: Icon(Icons.medical_services_outlined),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _licenseController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'License Number',
                      hintText: 'MBBS-XXXXXX',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: _requiredValidator,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              FormSectionCard(
                children: [
                  const SectionLabel('Contact Information', icon: Icons.contact_mail_outlined),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'name@clinic.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: _emailValidator,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      hintText: '01XXXXXXXXX',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: _requiredValidator,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------- Professional Details Card ----------
              // Credential edits here send an approved account back for
              // re-review (see _handleSave).
              FormSectionCard(
                children: [
                  const SectionLabel('Professional Details', icon: Icons.school_outlined),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Professional title',
                      hintText: 'e.g. Consultant, Surgeon, Dentist',
                      prefixIcon: Icon(Icons.assignment_ind_outlined),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _degreeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Degree',
                      hintText: 'e.g. MBBS',
                      prefixIcon: Icon(Icons.workspace_premium_outlined),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _institutionController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Institution graduated from',
                      hintText: 'e.g. Sylhet MAG Osmani Medical College',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 16),
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
                          validator: _requiredValidator,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _specialtiesController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Specialties',
                      hintText: 'e.g. Cardiology, ENT',
                      prefixIcon:
                          Icon(Icons.medical_services_outlined),
                    ),
                    validator: _specialtiesValidator,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _qualificationsController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Qualifications',
                      hintText: 'e.g. MBBS, FCPS (Medicine)',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _chamberController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Institution / Chamber name',
                      hintText: 'e.g. City Clinic, Zindabazar',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _clinicAddressController,
                    textCapitalization: TextCapitalization.words,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Clinic Address',
                      hintText: 'e.g. Zindabazar, Sylhet',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: _requiredValidator,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------- About Card ----------
              FormSectionCard(
                children: [
                  const SectionLabel('About', icon: Icons.info_outline),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      hintText: 'A short introduction patients will see on your profile...',
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
          label: 'Save Changes',
        ),
      ),
    );
  }
}