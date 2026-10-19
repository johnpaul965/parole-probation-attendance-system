import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/utils/firebase_config.dart';
import 'package:last/features/auth/models/officer_profile.dart';

class OfficerProfileService {
  OfficerProfileService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<OfficerProfile?> getById(String officerId) async {
    if (!FirebaseConfig.canUseFirestore || officerId.isEmpty) return null;

    final officerDoc = await _db.collection(FirestoreCollections.officers).doc(officerId).get();
    if (officerDoc.exists) {
      return OfficerProfile.fromMap(officerId, officerDoc.data()!);
    }

    final userDoc = await _db.collection(FirestoreCollections.users).doc(officerId).get();
    if (!userDoc.exists) return null;
    return OfficerProfile.fromMap(officerId, userDoc.data()!);
  }

  Stream<OfficerProfile?> watchById(String officerId) {
    if (!FirebaseConfig.canUseFirestore || officerId.isEmpty) {
      return Stream.value(null);
    }

    return _db.collection(FirestoreCollections.users).doc(officerId).snapshots().asyncMap(
      (userSnap) async {
        if (!userSnap.exists) return null;
        final officerExtra =
            await _db.collection(FirestoreCollections.officers).doc(officerId).get();
        final merged = {
          ...userSnap.data()!,
          if (officerExtra.exists) ...officerExtra.data()!,
        };
        return OfficerProfile.fromMap(officerId, merged);
      },
    );
  }
}
