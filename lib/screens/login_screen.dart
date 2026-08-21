import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum LoginRole { doctor, nurse, admin }

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  LoginRole _selectedRole = LoginRole.doctor;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or phone is required';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text('Welcome Back', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(width: 6),
                    const Text('👋', style: TextStyle(fontSize: 24)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to continue',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textGray),
                ),
                const SizedBox(height: 32),

                // ---------- Email / Phone ----------
                Text('Email / Phone', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'doctor@example.com'),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 20),

                // ---------- Password ----------
                Text('Password', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.iconGray,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password reset link sent')),
                      );
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 12),

                // ---------- Login as ----------
                Text('Login as', style: Theme.of(context).textTheme.titleMedium),
                RadioListTile<LoginRole>(
                  value: LoginRole.doctor,
                  groupValue: _selectedRole,
                  title: const Text('Doctor'),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) => setState(() => _selectedRole = value!),
                ),
                RadioListTile<LoginRole>(
                  value: LoginRole.nurse,
                  groupValue: _selectedRole,
                  title: const Text('Nurse'),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) => setState(() => _selectedRole = value!),
                ),
                RadioListTile<LoginRole>(
                  value: LoginRole.admin,
                  groupValue: _selectedRole,
                  title: const Text('Admin'),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) => setState(() => _selectedRole = value!),
                ),
                const SizedBox(height: 20),

                // ---------- Login button ----------
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.cardWhite),
                  )
                      : const Text('Login'),
                ),
                const SizedBox(height: 20),

                Center(
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sign up coming soon')),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: const [
                          TextSpan(
                            text: 'Sign up',
                            style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}