import 'package:flutter/material.dart';
import 'package:last/core/theme/app_colors.dart';

/// Online / offline indicator badge.
class LocationStatusBadge extends StatelessWidget {
  const LocationStatusBadge({
    super.key,
    required this.isOnline,
    this.label,
  });

  final bool isOnline;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = label ?? (isOnline ? 'Online' : 'Offline');
    final color = isOnline ? AppColors.success : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
