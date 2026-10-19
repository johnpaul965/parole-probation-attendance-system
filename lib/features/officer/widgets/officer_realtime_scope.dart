import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:last/core/services/notification_provider.dart';
import 'package:last/core/utils/app_logger.dart';
import 'package:last/core/utils/firebase_config.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/officer/providers/dashboard_provider.dart';
import 'package:last/features/tracking/providers/tracking_provider.dart';

/// Keeps officer dashboard + notifications synced on every officer tab.
class OfficerRealtimeScope extends StatefulWidget {
  const OfficerRealtimeScope({super.key, required this.child});

  final Widget child;

  @override
  State<OfficerRealtimeScope> createState() => _OfficerRealtimeScopeState();
}

class _OfficerRealtimeScopeState extends State<OfficerRealtimeScope> {
  String? _lastOfficerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRealtime());
  }

  void _startRealtime() {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      AppLogger.d('OfficerRealtimeScope', 'Waiting for auth user');
      return;
    }
    if (_lastOfficerId == user.id) return;
    _lastOfficerId = user.id;

    AppLogger.d('OfficerRealtimeScope', 'Starting realtime', user.id);

    if (FirebaseConfig.canUseFirestore) {
      context.read<DashboardProvider>().startListening(user.id);
      context.read<NotificationProvider>().watch(user.id);
      context.read<TrackingProvider>().startWatchingAssigned(
            requester: user,
            officerId: user.id,
          );
    } else {
      AppLogger.d('OfficerRealtimeScope', 'Firebase not ready — dashboard in offline mode');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user != null && user.id != _lastOfficerId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startRealtime());
    }
    return widget.child;
  }
}
