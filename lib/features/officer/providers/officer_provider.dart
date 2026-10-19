import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:last/features/activities/models/activity_model.dart';
import 'package:last/features/activities/services/activity_service.dart';
import 'package:last/features/officer/models/parolee_summary.dart';
import 'package:last/features/officer/services/officer_service.dart';

/// Officer-scoped provider for activity management and parolee roster.
class OfficerProvider extends ChangeNotifier {
  OfficerProvider({
    OfficerService? officerService,
    ActivityService? activityService,
  })  : _officerService = officerService ?? createOfficerService(),
        _activityService = activityService ?? ActivityService();

  final OfficerService _officerService;
  final ActivityService _activityService;

  List<ParoleeSummary> _parolees = [];
  List<ActivityModel> _recentActivities = [];
  bool _loading = false;
  String? _error;
  StreamSubscription? _activitySub;

  List<ParoleeSummary> get parolees => _parolees;
  List<ActivityModel> get recentActivities => _recentActivities;
  bool get isLoading => _loading;
  String? get error => _error;

  StreamSubscription<DashboardSnapshot>? _dashSub;

  void listenParolees(String officerId) {
    _dashSub?.cancel();
    _loading = true;
    notifyListeners();
    _dashSub = _officerService.watchDashboard(officerId).listen(
      (snap) {
        _parolees = snap.parolees;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (_) {
        _error = 'Failed to load parolees';
        _loading = false;
        notifyListeners();
      },
    );
  }

  void listenActivities(String officerId) {
    _activitySub?.cancel();
    _activitySub = _activityService.watchForOfficer(officerId).listen(
      (list) {
        _recentActivities = list.take(5).toList();
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _activitySub?.cancel();
    _dashSub?.cancel();
    super.dispose();
  }
}
