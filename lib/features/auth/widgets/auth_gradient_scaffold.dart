import 'package:flutter/material.dart';
import 'package:last/core/theme/app_colors.dart';

class AuthGradientScaffold extends StatelessWidget {
  const AuthGradientScaffold({
    super.key,
    required this.child,
    this.topRight,
  });

  final Widget child;
  final Widget? topRight;

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
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: child,
                  ),
                ),
              ),
              if (topRight != null)
                Positioned(
                  top: 4,
                  right: 8,
                  child: topRight!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
