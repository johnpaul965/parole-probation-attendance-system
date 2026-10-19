enum ActivityType {
  treePlanting,
  communityCleanup,
  counselingSession,
  other;

  String get label {
    switch (this) {
      case ActivityType.treePlanting:
        return 'Tree Planting';
      case ActivityType.communityCleanup:
        return 'Community Clean-Up Drive';
      case ActivityType.counselingSession:
        return 'Counseling Session';
      case ActivityType.other:
        return 'Other';
    }
  }

  static ActivityType fromString(String value) {
    return ActivityType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => ActivityType.other,
    );
  }
}

enum ActivityStatus {
  pending,
  ongoing,
  completed,
  missed;

  String get label {
    switch (this) {
      case ActivityStatus.pending:
        return 'Pending';
      case ActivityStatus.ongoing:
        return 'Ongoing';
      case ActivityStatus.completed:
        return 'Completed';
      case ActivityStatus.missed:
        return 'Missed';
    }
  }

  static ActivityStatus fromString(String value) {
    return ActivityStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ActivityStatus.pending,
    );
  }
}

class ActivityModel {
  ActivityModel({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.location,
    required this.scheduleDate,
    required this.assignedParoleeIds,
    required this.assignedOfficerId,
    required this.status,
    required this.createdAt,
    this.completedParoleeIds = const [],
    this.officerName,
  });

  final String id;
  final String title;
  final ActivityType type;
  final String description;
  final String location;
  final DateTime scheduleDate;
  final List<String> assignedParoleeIds;
  final String assignedOfficerId;
  final ActivityStatus status;
  final DateTime createdAt;
  final List<String> completedParoleeIds;
  final String? officerName;

  int get totalAssigned => assignedParoleeIds.length;
  int get totalCompleted => completedParoleeIds.length;
  double get completionRate =>
      totalAssigned == 0 ? 0 : (totalCompleted / totalAssigned) * 100;

  bool isAssignedTo(String paroleeId) => assignedParoleeIds.contains(paroleeId);
  bool isCompletedBy(String paroleeId) => completedParoleeIds.contains(paroleeId);

  Map<String, dynamic> toMap() => {
        'title': title,
        'type': type.name,
        'description': description,
        'location': location,
        'scheduleDate': scheduleDate.toIso8601String(),
        'assignedParolees': assignedParoleeIds,
        'assignedOfficerId': assignedOfficerId,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'completedParolees': completedParoleeIds,
        if (officerName != null) 'officerName': officerName,
      };

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      type: ActivityType.fromString(map['type'] as String? ?? 'other'),
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? '',
      scheduleDate:
          DateTime.tryParse(map['scheduleDate'] as String? ?? '') ?? DateTime.now(),
      assignedParoleeIds: List<String>.from(map['assignedParolees'] as List? ?? []),
      assignedOfficerId: map['assignedOfficerId'] as String? ?? '',
      status: ActivityStatus.fromString(map['status'] as String? ?? 'pending'),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      completedParoleeIds: List<String>.from(map['completedParolees'] as List? ?? []),
      officerName: map['officerName'] as String?,
    );
  }

  ActivityModel copyWith({
    ActivityStatus? status,
    List<String>? completedParoleeIds,
  }) {
    return ActivityModel(
      id: id,
      title: title,
      type: type,
      description: description,
      location: location,
      scheduleDate: scheduleDate,
      assignedParoleeIds: assignedParoleeIds,
      assignedOfficerId: assignedOfficerId,
      status: status ?? this.status,
      createdAt: createdAt,
      completedParoleeIds: completedParoleeIds ?? this.completedParoleeIds,
      officerName: officerName,
    );
  }
}

class ActivityStats {
  const ActivityStats({
    required this.total,
    required this.ongoing,
    required this.completed,
    required this.missed,
    required this.pending,
  });

  final int total;
  final int ongoing;
  final int completed;
  final int missed;
  final int pending;
}
