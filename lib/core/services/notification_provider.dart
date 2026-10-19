import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:last/core/services/notification_service.dart';
import 'package:last/features/shared/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationService? service})
      : _service = service ?? createNotificationService();

  final NotificationService _service;
  List<NotificationModel> _items = [];
  bool _loading = false;
  String? _error;
  StreamSubscription<List<NotificationModel>>? _sub;

  List<NotificationModel> get items => _items;
  int get unreadCount => _items.where((n) => !n.read).length;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> initialize() async {
    await _service.initializeMessaging();
  }

  void watch(String userId) {
    _sub?.cancel();
    _loading = true;
    _error = null;
    notifyListeners();

    _sub = _service.watchForUser(userId).listen(
      (data) {
        _items = data;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (_) {
        _error = 'Failed to load notifications';
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<void> markRead(String id) async {
    try {
      await _service.markRead(id);
      final idx = _items.indexWhere((n) => n.id == id);
      if (idx != -1) {
        _items[idx] = _items[idx].copyWith(read: true);
        notifyListeners();
      }
    } catch (_) {
      _error = 'Failed to update notification';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
