import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:last/core/theme/app_colors.dart';

/// Shows relative or absolute last-update time.
class LastUpdatedWidget extends StatelessWidget {
  const LastUpdatedWidget({
    super.key,
    required this.timestamp,
    this.label = 'Last Updated',
  });

  final DateTime? timestamp;
  final String label;

  String _format(DateTime? dt) {
    if (dt == null) return 'Never';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: ${_format(timestamp)}',
      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
    );
  }
}
