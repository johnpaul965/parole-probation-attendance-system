import 'package:flutter/material.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/tracking/models/check_in_proximity.dart';

class CheckInProximityBadge extends StatelessWidget {
  const CheckInProximityBadge({
    super.key,
    required this.result,
    this.compact = false,
  });

  final CheckInProximityResult result;
  final bool compact;

  Color get _color => switch (result.status) {
        CheckInProximityStatus.inside => AppColors.success,
        CheckInProximityStatus.outside => AppColors.officer,
        CheckInProximityStatus.gpsUnavailable => AppColors.warning,
        CheckInProximityStatus.locationUnverified => AppColors.textMuted,
        CheckInProximityStatus.unauthorized => AppColors.error,
      };

  String get _label {
    if (result.status == CheckInProximityStatus.inside ||
        result.status == CheckInProximityStatus.outside) {
      final base = result.status.label;
      if (result.distanceMeters != null) {
        return '$base · ${result.distanceMeters!.round()} m';
      }
      return base;
    }
    return result.status.label;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.radar, size: compact ? 12 : 14, color: _color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              result.isSimulated ? '$_label (sim)' : _label,
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
