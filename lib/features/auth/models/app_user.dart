import 'package:last/features/auth/models/supervision_period.dart';
import 'package:last/features/auth/models/user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.department,
    this.caseNumber,
    this.officerId,
    this.trackerId,
    this.avatarInitials,
    this.phone,
    this.isActive = true,
    this.supervisionStartDate,
    this.supervisionEndDate,
    this.supervisionIsSuspended = false,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? department;
  final String? caseNumber;
  final String? officerId;
  final String? trackerId;
  final String? avatarInitials;
  final String? phone;
  final bool isActive;
  final String? supervisionStartDate;
  final String? supervisionEndDate;
  final bool supervisionIsSuspended;

  SupervisionSnapshot get supervision => SupervisionPeriod.compute(
        startIso: supervisionStartDate,
        endIso: supervisionEndDate,
        isSuspended: supervisionIsSuspended,
      );

  String get initials {
    if (avatarInitials != null && avatarInitials!.isNotEmpty) {
      return avatarInitials!;
    }
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role.name,
        'department': department,
        'caseNumber': caseNumber,
        'officerId': officerId,
        'trackerId': trackerId,
        'avatarInitials': avatarInitials,
        'phone': phone,
        'isActive': isActive,
        'supervisionStartDate': supervisionStartDate,
        'supervisionEndDate': supervisionEndDate,
        'supervisionIsSuspended': supervisionIsSuspended,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String? ?? 'parolee'),
      department: map['department'] as String?,
      caseNumber: map['caseNumber'] as String?,
      officerId: map['officerId'] as String? ?? map['assignedOfficerId'] as String?,
      trackerId: map['trackerId'] as String? ?? map['assignedTrackerId'] as String?,
      avatarInitials: map['avatarInitials'] as String?,
      phone: map['phone'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      supervisionStartDate: _isoFrom(map['supervisionStartDate']),
      supervisionEndDate: _isoFrom(map['supervisionEndDate']),
      supervisionIsSuspended: map['supervisionIsSuspended'] as bool? ?? false,
    );
  }

  static String? _isoFrom(Object? raw) {
    final parsed = SupervisionPeriod.parseDate(raw);
    return parsed == null ? null : SupervisionPeriod.formatIso(parsed);
  }

  AppUser copyWith({
    String? fullName,
    String? phone,
    String? department,
    bool? isActive,
    String? trackerId,
    String? supervisionStartDate,
    String? supervisionEndDate,
    bool? supervisionIsSuspended,
  }) {
    return AppUser(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role,
      department: department ?? this.department,
      caseNumber: caseNumber,
      officerId: officerId,
      trackerId: trackerId ?? this.trackerId,
      avatarInitials: avatarInitials,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      supervisionStartDate: supervisionStartDate ?? this.supervisionStartDate,
      supervisionEndDate: supervisionEndDate ?? this.supervisionEndDate,
      supervisionIsSuspended: supervisionIsSuspended ?? this.supervisionIsSuspended,
    );
  }
}
