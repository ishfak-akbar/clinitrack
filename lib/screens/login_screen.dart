import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final ok = await context.read<AuthProvider>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<AuthProvider>().errorMessage.isEmpty
              ? 'Sign in failed'
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
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

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
              AppColors.darkCard.withValues(alpha: 0.9),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ---------- Logo ----------
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
                    const SizedBox(height: 16),

                    Text(
                      'CliniTrack',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Clinic Assistant',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ---------- Card ----------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : accent.withValues(alpha: 0.18),
                        ),
                        boxShadow: isDark
                            ? []
                            : [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Welcome Back',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in to access your clinic workspace',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                labelText: 'Email or phone',
                                labelStyle: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textGray,
                                ),
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  color: accent,
                                  size: 22,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.darkSurface
                                    : const Color(0xFFF7FBFA),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email or phone is required';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textGray,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: accent,
                                  size: 22,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.iconGray,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.darkSurface
                                    : const Color(0xFFF7FBFA),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 6),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Sign In button
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: isDark
                                      ? AppColors.darkBackground
                                      : Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: isDark
                                        ? AppColors.darkBackground
                                        : Colors.white,
                                  ),
                                )
                                    : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/register');
                          },
                          child: const Text('Register'),
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