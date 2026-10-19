class ScheduleModel {
  ScheduleModel({
    required this.id,
    required this.paroleeId,
    required this.paroleeName,
    required this.officerId,
    required this.scheduledAt,
    required this.location,
    required this.type,
    this.notes,
  });

  final String id;
  final String paroleeId;
  final String paroleeName;
  final String officerId;
  final DateTime scheduledAt;
  final String location;
  final String type;
  final String? notes;

  Map<String, dynamic> toMap() => {
        'id': id,
        'paroleeId': paroleeId,
        'paroleeName': paroleeName,
        'officerId': officerId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'location': location,
        'type': type,
        'notes': notes,
      };

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'] as String? ?? '',
      paroleeId: map['paroleeId'] as String? ?? '',
      paroleeName: map['paroleeName'] as String? ?? '',
      officerId: map['officerId'] as String? ?? '',
      scheduledAt: DateTime.tryParse(map['scheduledAt'] as String? ?? '') ?? DateTime.now(),
      location: map['location'] as String? ?? '',
      type: map['type'] as String? ?? 'Check-in',
      notes: map['notes'] as String?,
    );
  }
}
