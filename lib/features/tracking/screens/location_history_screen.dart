import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/tracking/providers/tracking_provider.dart';
import 'package:last/features/tracking/widgets/location_history_panel.dart';

class LocationHistoryScreen extends StatefulWidget {
  const LocationHistoryScreen({super.key, required this.paroleeId});

  final String paroleeId;

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  LocationHistoryFilter _filter = LocationHistoryFilter.today;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;
      final tracking = context.read<TrackingProvider>();
      if (tracking.activeTracking?.paroleeId != widget.paroleeId) {
        tracking.startWatchingParolee(requester: user, paroleeId: widget.paroleeId);
      }
      _loadHistory();
    });
  }

  Future<void> _loadHistory({bool append = false}) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final (start, end) = _filter.range(customStart: _customStart, customEnd: _customEnd);
    await context.read<TrackingProvider>().loadLocationHistory(
          requester: user,
          paroleeId: widget.paroleeId,
          start: start,
          end: end,
          append: append,
        );
  }

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (range != null) {
      setState(() {
        _filter = LocationHistoryFilter.custom;
        _customStart = range.start;
        _customEnd = range.end.add(const Duration(hours: 23, minutes: 59));
      });
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracking = context.watch<TrackingProvider>();
    final summary = tracking.activeTracking;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Location History'),
        backgroundColor: AppColors.officer,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: LocationHistoryFilter.values.map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f.label),
                    selected: selected,
                    onSelected: (_) async {
                      if (f == LocationHistoryFilter.custom) {
                        await _pickCustomRange();
                      } else {
                        setState(() => _filter = f);
                        await _loadHistory();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadHistory(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  LocationHistoryPanel(
                    records: tracking.locationHistory,
                    isLoading: tracking.isHistoryLoading,
                    error: tracking.historyError,
                    onRetry: () => _loadHistory(),
                    onLoadMore: tracking.hasMoreHistory ? () => _loadHistory(append: true) : null,
                    hasMore: tracking.hasMoreHistory,
                    paroleeName: summary?.fullName,
                    filterLabel: _filter == LocationHistoryFilter.custom && _customStart != null
                        ? 'Filtered: ${_customStart!.toLocal().toString().split(' ').first} — ${_customEnd!.toLocal().toString().split(' ').first}'
                        : _filter.label,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
