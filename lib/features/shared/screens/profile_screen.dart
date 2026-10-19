import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/activities/services/officer_profile_service.dart';
import 'package:last/features/activities/widgets/assigned_officer_card.dart';
import 'package:last/features/auth/models/officer_profile.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _officerService = OfficerProfileService();
  StreamSubscription<OfficerProfile?>? _officerSub;
  OfficerProfile? _officer;
  bool _officerLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?.fullName ?? '';
    _phoneController.text = user?.phone ?? '';
    _listenOfficer(user);
  }

  void _listenOfficer(dynamic user) {
    _officerSub?.cancel();
    if (user == null || user.role != UserRole.parolee) return;
    final officerId = user.officerId as String?;
    if (officerId == null || officerId.isEmpty) return;
    setState(() => _officerLoading = true);
    _officerSub = _officerService.watchById(officerId).listen(
      (profile) {
        if (mounted) {
          setState(() {
            _officer = profile;
            _officerLoading = false;
          });
        }
      },
      onError: (_) {
        if (mounted) setState(() => _officerLoading = false);
      },
    );
  }

  @override
  void dispose() {
    _officerSub?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    final auth = context.read<AuthProvider>();
    final user = auth.user!;
    auth.updateProfile(user.copyWith(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.officer.withValues(alpha: 0.15),
              child: Text(
                user.initials,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.officer),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(user.role.label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          if (user.role == UserRole.parolee) ...[
            const SizedBox(height: 24),
            AssignedOfficerCard(officer: _officer, loading: _officerLoading),
          ],
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: user.email,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
            keyboardType: TextInputType.phone,
          ),
          if (user.caseNumber != null) ...[
            const SizedBox(height: 12),
            TextFormField(
              initialValue: user.caseNumber,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Case Number'),
            ),
          ],
          if (user.department != null) ...[
            const SizedBox(height: 12),
            TextFormField(
              initialValue: user.department,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Department'),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Save Changes')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}
