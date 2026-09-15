import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final ok = await context.read<AuthProvider>().register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<AuthProvider>().errorMessage.isEmpty
              ? 'Registration failed'
              : context.read<AuthProvider>().errorMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent =
    isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              AppColors.darkBackground,
              AppColors.darkSurface,
              AppColors.darkCard,
            ]
                : [
              const Color(0xFFE8F5F4),
              AppColors.screenTintedBackground,
              const Color(0xFFD6EFEC),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/cliniTrackIcon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.local_hospital_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Create Account',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Join CliniTrack and manage your clinic with ease',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 28),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Full name is required'
                                    : null,
                              ),

                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: Icon(
                                    Icons.alternate_email_rounded,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Email is required';
                                  }
                                  final ok = RegExp(r'^[\w\.\-+]+@[\w\-]+\.[\w\-.]+$')
                                      .hasMatch(v.trim());
                                  if (!ok) return 'Enter a valid email';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (v.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _confirmController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: const Icon(
                                    Icons.lock_reset_outlined,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (v) {
                                  if (v != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _handleRegister,
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person_add_alt_1_rounded,
                                        ),
                                  label: Text(_isLoading
                                      ? 'Creating...'
                                      : 'Create Account'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pushReplacementNamed('/login');
                          },
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
