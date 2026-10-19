import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:last/core/constants/app_constants.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/utils/validators.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/auth/widgets/auth_gradient_scaffold.dart';
import 'package:last/features/auth/widgets/auth_text_field.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.role = UserRole.parolee});

  final UserRole role;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneController = TextEditingController();

  bool get _officer => widget.role == UserRole.officer;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _nameController.text,
      role: widget.role,
      phone: _officer ? null : _phoneController.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. Verify your email, then sign in.'),
        ),
      );
      context.go(_officer ? '/login?staff=1' : '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final accent = _officer ? AppColors.officer : AppColors.parolee;

    return AuthGradientScaffold(
      topRight: TextButton(
        onPressed: () => context.go(_officer ? '/login?staff=1' : '/login'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white70,
          visualDensity: VisualDensity.compact,
        ),
        child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      child: Form(
        key: _formKey,
        child: AuthFormCard(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Icon(
                  _officer ? Icons.badge_outlined : Icons.person_add_alt_1,
                  size: 32,
                  color: const Color(0xFF90CAF9),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                AppConstants.appName,
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                _officer ? 'Create officer account' : 'Create your account',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
              ),
              const SizedBox(height: 22),
              AuthTextField(
                label: 'Full name',
                controller: _nameController,
                validator: Validators.fullName,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Email',
                controller: _emailController,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
              ),
              if (!_officer) ...[
                const SizedBox(height: 14),
                AuthTextField(
                  label: 'Phone number',
                  controller: _phoneController,
                  validator: Validators.phone,
                  keyboardType: TextInputType.phone,
                ),
              ],
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Password',
                controller: _passwordController,
                validator: Validators.registerPassword,
                obscure: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Confirm password',
                controller: _confirmController,
                validator: (v) => Validators.confirmPassword(v, _passwordController.text),
                obscure: true,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: auth.isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_officer ? 'Create officer account' : 'Create account'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go(_officer ? '/login?staff=1' : '/login'),
                child: const Text(
                  'Already have an account? Sign in',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
