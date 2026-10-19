import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus {
  checkedIn('Checked In'),
  confirmed('Confirmed'),
  pending('Pending'),
  missed('Missed');

  const AttendanceStatus(this.label);
  final String label;

  static AttendanceStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'checkedin':
      case 'checked_in':
      case 'present':
        return AttendanceStatus.checkedIn;
      case 'confirmed':
        return AttendanceStatus.confirmed;
      case 'missed':
      case 'absent':
        return AttendanceStatus.missed;
      case 'pending':
      default:
        return AttendanceStatus.pending;
    }
  }
}

class AttendanceRecord {
  AttendanceRecord({
    required this.id,
    required this.ticketId,
    required this.paroleeId,
    this.paroleeName = 'Parolee',
    this.officerId,
    this.checkInTime,
    this.scheduledTime,
    this.location,
    this.qrPayload,
    this.verified = false,
    this.verifiedAt,
    this.verifiedBy,
    this.status = AttendanceStatus.pending,
    this.notes,
  });

  final String id;
  final String ticketId;
  final String paroleeId;
  final String paroleeName;
  final String? officerId;
  final DateTime? checkInTime;
  final DateTime? scheduledTime;
  final String? location;
  final String? qrPayload;
  final bool verified;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final AttendanceStatus status;
  final String? notes;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'paroleeId': paroleeId,
      'paroleeName': paroleeName,
      'officerId': officerId,
      'checkInTime': checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'scheduledTime': scheduledTime != null ? Timestamp.fromDate(scheduledTime!) : null,
      'location': location,
      'qrPayload': qrPayload,
      'verified': verified,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verifiedBy': verifiedBy,
      'status': status.name,
      'notes': notes,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return AttendanceRecord(
      id: map['id'] as String? ?? '',
      ticketId: map['ticketId'] as String? ?? '',
      paroleeId: map['paroleeId'] as String? ?? '',
      paroleeName: map['paroleeName'] as String? ?? 'Parolee',
      officerId: map['officerId'] as String?,
      checkInTime: parseDate(map['checkInTime']),
      scheduledTime: parseDate(map['scheduledTime']),
      location: map['location'] as String?,
      qrPayload: map['qrPayload'] as String?,
      verified: map['verified'] as bool? ?? false,
      verifiedAt: parseDate(map['verifiedAt']),
      verifiedBy: map['verifiedBy'] as String?,
      status: AttendanceStatus.fromString(map['status'] as String? ?? 'pending'),
      notes: map['notes'] as String?,
    );
  }

  AttendanceRecord copyWith({
    String? id,
    String? ticketId,
    String? paroleeId,
    String? paroleeName,
    String? officerId,
    DateTime? checkInTime,
    DateTime? scheduledTime,
    String? location,
    String? qrPayload,
    bool? verified,
    DateTime? verifiedAt,
    String? verifiedBy,
    AttendanceStatus? status,
    String? notes,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      paroleeId: paroleeId ?? this.paroleeId,
      paroleeName: paroleeName ?? this.paroleeName,
      officerId: officerId ?? this.officerId,
      checkInTime: checkInTime ?? this.checkInTime,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      location: location ?? this.location,
      qrPayload: qrPayload ?? this.qrPayload,
      verified: verified ?? this.verified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
