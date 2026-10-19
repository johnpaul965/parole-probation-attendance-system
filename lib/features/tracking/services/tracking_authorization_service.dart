import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/models/user_role.dart';

class TrackingAuthorizationException implements Exception {
  TrackingAuthorizationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TrackingAuthorizationService {
  /// Validates that [requester] may access tracking for [parolee].
  void assertCanTrack(AppUser requester, AppUser parolee) {
    if (requester.role != UserRole.officer) {
      throw TrackingAuthorizationException(
        'You are not authorized to track this parolee.',
      );
    }

    if (!isAssignedOfficer(requester.id, parolee)) {
      throw TrackingAuthorizationException(
        'You are not authorized to track this parolee.',
      );
    }
  }

  bool canTrack(AppUser requester, AppUser parolee) {
    try {
      assertCanTrack(requester, parolee);
      return true;
    } on TrackingAuthorizationException {
      return false;
    }
  }

  /// Officer may track when parolee.assigned_officer_id == officer.id
  bool isAssignedOfficer(String officerId, AppUser parolee) {
    final assignedId = parolee.officerId;
    return assignedId != null && assignedId.isNotEmpty && assignedId == officerId;
  }
}
