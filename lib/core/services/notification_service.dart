import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/utils/firebase_config.dart';
import 'package:last/features/shared/models/notification_model.dart';
import 'package:uuid/uuid.dart';

abstract class NotificationService {
  Stream<List<NotificationModel>> watchForUser(String userId);
  Future<List<NotificationModel>> getForUser(String userId);
  Future<void> markRead(String id);
  Future<void> send({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
  });
  Future<void> initializeMessaging();
}

class FirebaseNotificationService implements NotificationService {
  FirebaseNotificationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<List<NotificationModel>> watchForUser(String userId) {
    if (!FirebaseConfig.canUseFirestore) {
      return Stream.value([]);
    }
    return _db
        .collection(FirestoreCollections.notifications)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => NotificationModel.fromMap({...d.data(), 'id': d.id}))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<List<NotificationModel>> getForUser(String userId) async {
    final snap = await _db
        .collection(FirestoreCollections.notifications)
        .where('userId', isEqualTo: userId)
        .get();
    final list = snap.docs
        .map((d) => NotificationModel.fromMap({...d.data(), 'id': d.id}))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> markRead(String id) async {
    await _db.collection(FirestoreCollections.notifications).doc(id).update({'read': true});
  }

  @override
  Future<void> send({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    final id = const Uuid().v4();
    await _db.collection(FirestoreCollections.notifications).doc(id).set({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
    });
  }

  @override
  Future<void> initializeMessaging() async {}
}

/// In-app notification list for demo / mock mode (no Firestore).
class InMemoryNotificationService implements NotificationService {
  InMemoryNotificationService();

  static final InMemoryNotificationService instance = InMemoryNotificationService();

  final List<NotificationModel> _items = [];
  final _controller = StreamController<List<NotificationModel>>.broadcast();

  @override
  Stream<List<NotificationModel>> watchForUser(String userId) {
    Future.microtask(() => _emit(userId));
    return _controller.stream.map((all) => all.where((n) => n.userId == userId).toList());
  }

  @override
  Future<List<NotificationModel>> getForUser(String userId) async {
    return _items.where((n) => n.userId == userId).toList();
  }

  @override
  Future<void> markRead(String id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(read: true);
      _controller.add(List.unmodifiable(_items));
    }
  }

  @override
  Future<void> send({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    _items.insert(
      0,
      NotificationModel(
        id: const Uuid().v4(),
        userId: userId,
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
      ),
    );
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<void> initializeMessaging() async {}

  void _emit(String userId) {
    _controller.add(_items.where((n) => n.userId == userId).toList());
  }
}

NotificationService createNotificationService() {
  if (FirebaseConfig.canUseFirestore) {
    return FirebaseNotificationService();
  }
  return InMemoryNotificationService.instance;
}
