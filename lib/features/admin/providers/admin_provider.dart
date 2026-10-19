import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:last/core/services/live_stats_service.dart';
import 'package:last/features/admin/services/admin_service.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/officer/models/live_stats.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider({
    AdminService? service,
    LiveStatsService? liveStatsService,
  })  : _service = service ?? createAdminService(),
        _liveStatsService = liveStatsService ?? LiveStatsService();

  final AdminService _service;
  final LiveStatsService _liveStatsService;
  List<AppUser> _users = [];
  bool _loading = false;
  String? _error;
  double _complianceRate = 0;
  List<LiveStats> _allLiveStats = [];
  StreamSubscription<List<AppUser>>? _usersSub;
  StreamSubscription<double>? _complianceSub;
  StreamSubscription<List<LiveStats>>? _liveSub;

  List<AppUser> get users => _users;
  List<AppUser> get officers =>
      _users.where((u) => u.role == UserRole.officer).toList();
  List<AppUser> get parolees =>
      _users.where((u) => u.role == UserRole.parolee).toList();
  bool get isLoading => _loading;
  String? get error => _error;
  double get complianceRate => _complianceRate;
  List<LiveStats> get allLiveStats => _allLiveStats;

  int get systemTotalCases =>
      _allLiveStats.fold(0, (sum, s) => sum + s.stats.totalCases);
  int get systemCheckedIn =>
      _allLiveStats.fold(0, (sum, s) => sum + s.stats.checkedIn);
  int get systemPending =>
      _allLiveStats.fold(0, (sum, s) => sum + s.stats.pending);
  int get systemMissed =>
      _allLiveStats.fold(0, (sum, s) => sum + s.stats.missed);

  int get totalUsers => _users.length;
  int get activeParolees => parolees.where((u) => u.isActive).length;

  void startListening() {
    _usersSub?.cancel();
    _complianceSub?.cancel();
    _loading = true;
    _error = null;
    notifyListeners();

    _usersSub = _service.watchAllUsers().listen(
      (data) {
        _users = data;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (_) {
        _error = 'Failed to load users';
        _loading = false;
        notifyListeners();
      },
    );

    _complianceSub = _service.watchComplianceRate().listen(
      (rate) {
        _complianceRate = rate;
        notifyListeners();
      },
    );

    _liveSub = _liveStatsService.watchAll().listen(
      (list) {
        _allLiveStats = list;
        notifyListeners();
      },
    );
  }

  Future<void> loadUsers() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _users = await _service.getAllUsers();
      _complianceRate = await _service.computeComplianceRate();
    } catch (_) {
      _error = 'Failed to load users';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> assignOfficer(String paroleeId, String officerId) async {
    try {
      await _service.assignOfficer(paroleeId, officerId);
    } catch (_) {
      _error = 'Failed to assign officer';
      notifyListeners();
    }
  }

  Future<void> removeOfficer(String paroleeId) async {
    try {
      await _service.removeOfficer(paroleeId);
    } catch (_) {
      _error = 'Failed to remove officer';
      notifyListeners();
    }
  }

  Future<void> toggleActive(String userId, bool active) async {
    try {
      await _service.toggleUserActive(userId, active);
    } catch (_) {
      _error = 'Failed to update user';
      notifyListeners();
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _service.deleteUser(userId);
      return true;
    } catch (_) {
      _error = 'Failed to remove user';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _complianceSub?.cancel();
    _liveSub?.cancel();
    super.dispose();
  }
}
