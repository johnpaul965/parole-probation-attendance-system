import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:last/core/constants/app_constants.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    try {
      final auth = context.read<AuthProvider>();
      await auth.initialize();
    } catch (_) {}
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && auth.user != null) {
      context.go('${auth.user!.role.routePrefix}/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.loginGradientStart,
              AppColors.loginGradientMid,
              AppColors.loginGradientEnd,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: 'app-logo',
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.gavel, size: 40, color: Color(0xFF64B5F6)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  AppConstants.appSubtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
