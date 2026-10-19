import 'package:flutter/material.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/auth/models/officer_profile.dart';

class AssignedOfficerCard extends StatelessWidget {
  const AssignedOfficerCard({
    super.key,
    required this.officer,
    this.loading = false,
  });

  final OfficerProfile? officer;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.officer.withValues(alpha: 0.1),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8, width: 140, child: ColoredBox(color: Color(0xFFE8ECF0))),
                    SizedBox(height: 8),
                    SizedBox(height: 8, width: 100, child: ColoredBox(color: Color(0xFFE8ECF0))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (officer == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.textMuted.withValues(alpha: 0.1),
                child: const Icon(Icons.person_off_outlined, color: AppColors.textMuted),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Officer Assigned',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Contact your PPA office to assign a supervising officer.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final o = officer!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.officer.withValues(alpha: 0.2)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.officer.withValues(alpha: 0.06),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.officer.withValues(alpha: 0.15),
                  backgroundImage:
                      o.profileImage != null && o.profileImage!.isNotEmpty
                          ? NetworkImage(o.profileImage!)
                          : null,
                  child: o.profileImage == null || o.profileImage!.isEmpty
                      ? Text(
                          o.initials,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.officer,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Officer',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        o.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'ID: ${o.id}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow(Icons.email_outlined, 'Email', o.email),
            if (o.contact != null && o.contact!.isNotEmpty)
              _infoRow(Icons.phone_outlined, 'Contact', o.contact!),
            if (o.office != null && o.office!.isNotEmpty)
              _infoRow(Icons.business_outlined, 'Station / Office', o.office!),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.officer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
