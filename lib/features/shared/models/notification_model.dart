import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  checkIn('Check-in'),
  schedule('Schedule'),
  alert('Alert'),
  system('System'),
  success('Success'),
  reminder('Reminder'),
  warning('Warning'),
  info('Info');

  const NotificationType(this.label);
  final String label;

  static NotificationType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'checkin':
      case 'check_in':
        return NotificationType.checkIn;
      case 'schedule':
        return NotificationType.schedule;
      case 'alert':
        return NotificationType.alert;
      case 'success':
        return NotificationType.success;
      case 'reminder':
        return NotificationType.reminder;
      case 'warning':
        return NotificationType.warning;
      case 'info':
        return NotificationType.info;
      case 'system':
      default:
        return NotificationType.system;
    }
  }
}

class NotificationModel {
  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.read = false,
    this.data,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool read;
  final Map<String, dynamic>? data;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'read': read,
      'data': data,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return NotificationModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: NotificationType.fromString(map['type'] as String? ?? 'system'),
      createdAt: parseDate(map['createdAt']),
      read: map['read'] as bool? ?? false,
      data: map['data'] as Map<String, dynamic>?,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? createdAt,
    bool? read,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      data: data ?? this.data,
    );
  }
}
