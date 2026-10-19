import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  ScheduleModel({
    required this.id,
    required this.paroleeId,
    this.paroleeName = 'Parolee',
    required this.officerId,
    required this.scheduledAt,
    required this.type,
    this.location = 'Tacloban City PPO',
    this.notes,
  });

  final String id;
  final String paroleeId;
  final String paroleeName;
  final String officerId;
  final DateTime scheduledAt;
  final String type;
  final String location;
  final String? notes;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paroleeId': paroleeId,
      'paroleeName': paroleeName,
      'officerId': officerId,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'type': type,
      'location': location,
      'notes': notes,
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return ScheduleModel(
      id: map['id'] as String? ?? '',
      paroleeId: map['paroleeId'] as String? ?? '',
      paroleeName: map['paroleeName'] as String? ?? 'Parolee',
      officerId: map['officerId'] as String? ?? '',
      scheduledAt: parseDate(map['scheduledAt']),
      type: map['type'] as String? ?? 'General Supervision',
      location: map['location'] as String? ?? 'Tacloban City PPO',
      notes: map['notes'] as String?,
    );
  }

  ScheduleModel copyWith({
    String? id,
    String? paroleeId,
    String? paroleeName,
    String? officerId,
    DateTime? scheduledAt,
    String? type,
    String? location,
    String? notes,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      paroleeId: paroleeId ?? this.paroleeId,
      paroleeName: paroleeName ?? this.paroleeName,
      officerId: officerId ?? this.officerId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      type: type ?? this.type,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }
}
