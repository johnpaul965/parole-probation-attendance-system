import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:last/features/activities/models/activity_model.dart';
import 'package:last/features/activities/services/activity_service.dart';

class ActivityProvider extends ChangeNotifier {
  ActivityProvider({ActivityService? service})
      : _service = service ?? ActivityService();

  final ActivityService _service;

  List<ActivityModel> _activities = [];
  ActivityStats _stats = const ActivityStats(
    total: 0,
    ongoing: 0,
    completed: 0,
    missed: 0,
    pending: 0,
  );
  bool _loading = false;
  String? _error;
  String _search = '';
  ActivityStatus? _statusFilter;
  ActivityType? _typeFilter;
  String? _officerFilter;

  StreamSubscription<List<ActivityModel>>? _sub;
  StreamSubscription<ActivityStats>? _statsSub;

  List<ActivityModel> get activities => _filtered;
  ActivityStats get stats => _stats;
  bool get isLoading => _loading;
  String? get error => _error;
  String get search => _search;
  ActivityStatus? get statusFilter => _statusFilter;
  ActivityType? get typeFilter => _typeFilter;
  String? get officerFilter => _officerFilter;

  List<ActivityModel> get _filtered {
    var list = List<ActivityModel>.from(_activities);
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (a) =>
                a.title.toLowerCase().contains(q) ||
                a.location.toLowerCase().contains(q) ||
                a.type.label.toLowerCase().contains(q),
          )
          .toList();
    }
    if (_statusFilter != null) {
      list = list.where((a) => a.status == _statusFilter).toList();
    }
    if (_typeFilter != null) {
      list = list.where((a) => a.type == _typeFilter).toList();
    }
    if (_officerFilter != null && _officerFilter!.isNotEmpty) {
      list = list.where((a) => a.assignedOfficerId == _officerFilter).toList();
    }
    return list;
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setStatusFilter(ActivityStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setTypeFilter(ActivityType? type) {
    _typeFilter = type;
    notifyListeners();
  }

  void setOfficerFilter(String? officerId) {
    _officerFilter = officerId;
    notifyListeners();
  }

  void listenForOfficer(String officerId) {
    _cancel();
    _loading = true;
    _error = null;
    notifyListeners();

    _sub = _service.watchForOfficer(officerId).listen(
      (data) {
        _activities = data;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (_) {
        _error = 'Failed to load activities';
        _loading = false;
        notifyListeners();
      },
    );

    _statsSub = _service.watchStats(officerId: officerId).listen((s) {
      _stats = s;
      notifyListeners();
    });
  }

  void listenForParolee(String paroleeId) {
    _cancel();
    _loading = true;
    _error = null;
    notifyListeners();

    _sub = _service.watchForParolee(paroleeId).listen(
      (data) {
        _activities = data;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (_) {
        _error = 'Failed to load activities';
        _loading = false;
        notifyListeners();
      },
    );
  }

  void listenAll() {
    _cancel();
    _loading = true;
    _error = null;
    notifyListeners();

    _sub = _service.watchAll().listen(
      (data) {
        _activities = data;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (_) {
        _error = 'Failed to load activities';
        _loading = false;
        notifyListeners();
      },
    );

    _statsSub = _service.watchStats().listen((s) {
      _stats = s;
      notifyListeners();
    });
  }

  Future<void> createActivity({
    required String title,
    required ActivityType type,
    required String description,
    required String location,
    required DateTime scheduleDate,
    required String officerId,
    required String officerName,
    required List<String> paroleeIds,
  }) async {
    await _service.createActivity(
      title: title,
      type: type,
      description: description,
      location: location,
      scheduleDate: scheduleDate,
      officerId: officerId,
      officerName: officerName,
      paroleeIds: paroleeIds,
    );
  }

  Future<void> updateStatus(String activityId, ActivityStatus status) async {
    await _service.updateStatus(activityId, status);
  }

  Future<void> assignParolees(String activityId, List<String> paroleeIds) async {
    await _service.assignParolees(activityId, paroleeIds);
  }

  void _cancel() {
    _sub?.cancel();
    _statsSub?.cancel();
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }
}
