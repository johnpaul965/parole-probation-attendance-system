import 'package:flutter/material.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/services/route_simplification_service.dart';
import 'package:last/features/tracking/widgets/location_history_list.dart';
import 'package:last/features/tracking/widgets/tracking_map.dart';

/// Date range presets for location history.
enum LocationHistoryFilter {
  today,
  yesterday,
  last7Days,
  custom;

  (DateTime?, DateTime?) range({DateTime? customStart, DateTime? customEnd}) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return switch (this) {
      LocationHistoryFilter.today => (todayStart, now),
      LocationHistoryFilter.yesterday => (
          todayStart.subtract(const Duration(days: 1)),
          todayStart.subtract(const Duration(seconds: 1)),
        ),
      LocationHistoryFilter.last7Days => (todayStart.subtract(const Duration(days: 7)), now),
      LocationHistoryFilter.custom => (customStart, customEnd),
    };
  }

  String get label => switch (this) {
        LocationHistoryFilter.today => 'Today',
        LocationHistoryFilter.yesterday => 'Yesterday',
        LocationHistoryFilter.last7Days => 'Last 7 Days',
        LocationHistoryFilter.custom => 'Custom',
      };
}

/// Panel with map polyline + paginated history list.
class LocationHistoryPanel extends StatelessWidget {
  const LocationHistoryPanel({
    super.key,
    required this.records,
    required this.isLoading,
    this.error,
    this.onRetry,
    this.onLoadMore,
    this.hasMore = false,
    this.paroleeName,
    this.filterLabel,
  });

  final List<LocationRecord> records;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final String? paroleeName;
  final String? filterLabel;

  @override
  Widget build(BuildContext context) {
    final simplifier = RouteSimplificationService();
    final routePoints = simplifier.simplify(records.reversed.toList());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (routePoints.isNotEmpty)
          TrackingMapWidget(
            location: records.first,
            history: routePoints,
            options: const TrackingMapOptions(
              height: 200,
              showHistoryPolyline: true,
              showAccuracyRadius: false,
            ),
          ),
        const SizedBox(height: 16),
        if (paroleeName != null)
          Text(paroleeName!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        if (filterLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(filterLabel!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ),
        const SizedBox(height: 12),
        LocationHistoryList(
          records: records,
          isLoading: isLoading,
          error: error,
          onRetry: onRetry,
        ),
        if (hasMore && onLoadMore != null)
          Center(
            child: TextButton(onPressed: onLoadMore, child: const Text('Load More')),
          ),
      ],
    );
  }
}
