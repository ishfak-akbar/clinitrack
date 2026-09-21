import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/section_label.dart';
import '../widgets/form_section_card.dart';
import '../widgets/sticky_save_button.dart';
import '../widgets/user_avatar.dart';

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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    await context.read<AuthProvider>().updateProfile(
      name: _nameController.text.trim(),
      specialty: _specialtyController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      qualifications: _qualificationsController.text.trim(),
      experienceYears: _experienceController.text.trim(),
      clinicAddress: _clinicAddressController.text.trim(),
      bio: _bioController.text.trim(),
      // Step 6 moves these into this form; until then pass the stored
      // values through so saving never wipes the verification data.
      chamberName: context.read<AuthProvider>().chamberName,
      title: context.read<AuthProvider>().title,
      degree: context.read<AuthProvider>().degree,
      graduatingInstitution:
          context.read<AuthProvider>().graduatingInstitution,
      graduationYear: context.read<AuthProvider>().graduationYear,
      specialties: context.read<AuthProvider>().specialties,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
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
              FormSectionCard(
                children: [
                  const SectionLabel('Professional Details', icon: Icons.school_outlined),
                  const SizedBox(height: 8),
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
                    controller: _experienceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Years of Experience',
                      hintText: 'e.g. 5',
                      prefixIcon: Icon(Icons.work_history_outlined),
                    ),
                    validator: _requiredValidator,
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