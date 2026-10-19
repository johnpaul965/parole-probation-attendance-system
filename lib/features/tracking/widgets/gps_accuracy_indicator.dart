import 'package:flutter/material.dart';
import 'package:last/core/theme/app_colors.dart';

class GpsAccuracyIndicator extends StatelessWidget {
  const GpsAccuracyIndicator({super.key, this.accuracy, this.compact = false});

  final double? accuracy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (accuracy == null) {
      return Text('N/A', style: TextStyle(fontSize: compact ? 11 : 13, color: AppColors.textMuted));
    }

    final color = accuracy! <= 10
        ? AppColors.success
        : accuracy! <= 30
            ? AppColors.warning
            : AppColors.error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.my_location, size: compact ? 14 : 16, color: color),
        const SizedBox(width: 4),
        Text(
          '±${accuracy!.toStringAsFixed(0)}m',
          style: TextStyle(fontSize: compact ? 11 : 13, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
