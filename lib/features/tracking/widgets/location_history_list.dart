import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/widgets/gps_accuracy_indicator.dart';

class LocationHistoryList extends StatelessWidget {
  const LocationHistoryList({
    super.key,
    required this.records,
    this.isLoading = false,
    this.error,
    this.onRetry,
  });

  final List<LocationRecord> records;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, style: const TextStyle(color: AppColors.error)),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (records.isEmpty) {
      return const Center(
        child: Text('No location history found', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final r = records[i];
        final dt = r.recordedAt ?? r.receivedAt;
        return ListTile(
          leading: const Icon(Icons.place_outlined, color: AppColors.officer),
          title: Text(
            dt != null ? DateFormat('MMMM d, yyyy — hh:mm a').format(dt) : 'Unknown time',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${r.latitude.toStringAsFixed(4)}, ${r.longitude.toStringAsFixed(4)}',
            style: const TextStyle(fontSize: 11),
          ),
          trailing: GpsAccuracyIndicator(accuracy: r.accuracy, compact: true),
        );
      },
    );
  }
}
