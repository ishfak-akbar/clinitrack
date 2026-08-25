import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/section_label.dart';
import '../widgets/form_section_card.dart';
import '../widgets/sticky_save_button.dart';

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _licenseController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Center(
                child: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundImage: AssetImage('assets/doctor.png'),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
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
            ],
          ),
        ),
        bottomNavigationBar: StickySaveButton(
          isSaving: _isSaving,
          onPressed: _handleSave,
          label: 'Save Changes',
        ),
      ),
    );
  }
}