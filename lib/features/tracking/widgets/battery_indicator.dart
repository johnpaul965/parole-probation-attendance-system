import 'package:flutter/material.dart';
import 'package:last/core/theme/app_colors.dart';

class BatteryIndicator extends StatelessWidget {
  const BatteryIndicator({super.key, required this.level, this.compact = false});

  final int? level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (level == null) {
      return Text('N/A', style: TextStyle(fontSize: compact ? 11 : 13, color: AppColors.textMuted));
    }

    final color = level! < 20
        ? AppColors.error
        : level! < 50
            ? AppColors.warning
            : AppColors.success;

    IconData icon;
    if (level! >= 80) {
      icon = Icons.battery_full;
    } else if (level! >= 50) {
      icon = Icons.battery_5_bar;
    } else if (level! >= 20) {
      icon = Icons.battery_3_bar;
    } else {
      icon = Icons.battery_alert;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 16 : 18, color: color),
        const SizedBox(width: 4),
        Text(
          '$level%',
          style: TextStyle(fontSize: compact ? 11 : 13, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
