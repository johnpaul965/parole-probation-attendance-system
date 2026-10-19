import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last/core/utils/app_config.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> collection(String name) {
    return _db.collection(name);
  }

  Future<void> setDocument({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    await _db.collection(collection).doc(id).set(data, SetOptions(merge: merge));
  }

  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String id,
  }) async {
    final snap = await _db.collection(collection).doc(id).get();
    if (!snap.exists) return null;
    return {...snap.data()!, 'id': snap.id};
  }

  Future<void> deleteDocument({
    required String collection,
    required String id,
  }) async {
    await _db.collection(collection).doc(id).delete();
  }

  Stream<List<Map<String, dynamic>>> watchCollection(
    String collection, {
    Query<Map<String, dynamic>> Function(CollectionReference<Map<String, dynamic>>)?
        queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(collection);
    if (queryBuilder != null) {
      query = queryBuilder(_db.collection(collection));
    }
    return query.snapshots().map((snap) {
      return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    });
  }

  static bool get isAvailable => AppConfig.useFirebase;
}
