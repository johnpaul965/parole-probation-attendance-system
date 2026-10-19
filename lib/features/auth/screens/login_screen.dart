import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:last/core/constants/app_constants.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/utils/firebase_config.dart';
import 'package:last/core/utils/validators.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/auth/widgets/auth_gradient_scaffold.dart';
import 'package:last/features/auth/widgets/auth_text_field.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialOfficer = false});

  final bool initialOfficer;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _officerMode = widget.initialOfficer;

  UserRole get _role => _officerMode ? UserRole.officer : UserRole.parolee;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      email: _emailController.text,
      password: _passwordController.text,
      role: _role,
    );
    if (!mounted) return;
    if (ok) {
      context.go('${_role.routePrefix}/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final accent = _officerMode ? AppColors.officer : AppColors.parolee;

    return AuthGradientScaffold(
      topRight: TextButton(
        onPressed: () => setState(() => _officerMode = !_officerMode),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white70,
          visualDensity: VisualDensity.compact,
        ),
        child: Text(
          _officerMode ? 'Parolee sign in' : 'Officer',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      child: Form(
        key: _formKey,
        child: AuthFormCard(
          child: Column(
            children: [
              Hero(
                tag: 'app-logo',
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Icon(
                    _officerMode ? Icons.badge_outlined : Icons.gavel,
                    size: 34,
                    color: const Color(0xFF90CAF9),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                AppConstants.appName,
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                _officerMode ? 'Officer access' : AppConstants.appSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
              ),
              const SizedBox(height: 22),
              if (!FirebaseConfig.isConfigured)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'Demo mode: Firebase is not configured. Sign in works offline; dashboards need Firestore setup.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              AuthTextField(
                label: 'Email',
                controller: _emailController,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Password',
                controller: _passwordController,
                validator: Validators.password,
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
                      : Text(_officerMode ? 'Officer sign in' : 'Sign in'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/register', extra: _role),
                child: Text(
                  _officerMode ? 'Create officer account' : 'Create account',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
