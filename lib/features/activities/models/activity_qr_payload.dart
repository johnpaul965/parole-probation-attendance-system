import 'dart:convert';

class ActivityQrPayload {
  const ActivityQrPayload({
    required this.paroleeId,
    required this.paroleeName,
    required this.activityId,
    required this.assignedOfficerId,
    required this.activityTitle,
    required this.token,
    required this.timestamp,
  });

  final String paroleeId;
  final String paroleeName;
  final String activityId;
  final String assignedOfficerId;
  final String activityTitle;
  final String token;
  final DateTime timestamp;

  /// Legacy alias used by officer scanner validation.
  String get officerId => assignedOfficerId;

  Map<String, dynamic> toJson() => {
        'paroleeId': paroleeId,
        'paroleeName': paroleeName,
        'activityId': activityId,
        'assignedOfficerId': assignedOfficerId,
        'officerId': assignedOfficerId,
        'activityTitle': activityTitle,
        'token': token,
        'timestamp': timestamp.toIso8601String(),
      };

  /// Public QR content: opaque token + activity id only (no names or emails).
  String encode() {
    final json = jsonEncode({'t': token, 'a': activityId});
    if (json.isEmpty) {
      throw StateError('QR payload encoding produced empty string');
    }
    return json;
  }

  static ActivityQrPayload? decode(String raw) {
    try {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;

      Map<String, dynamic> map;
      if (trimmed.startsWith('{')) {
        map = jsonDecode(trimmed) as Map<String, dynamic>;
        if ((map['token'] == null || (map['token'] as String).isEmpty) &&
            map['t'] is String) {
          map = {
            ...map,
            'token': map['t'],
            'activityId': map['a'] ?? map['activityId'] ?? '',
          };
        }
      } else if (trimmed.startsWith('PPA_ACT|')) {
        final parts = trimmed.split('|');
        if (parts.length < 7) return null;
        map = {
          'paroleeId': parts[1],
          'paroleeName': parts[2],
          'activityId': parts[3],
          'assignedOfficerId': parts[4],
          'officerId': parts[4],
          'activityTitle': parts.length > 7 ? parts[7] : '',
          'token': parts[5],
          'timestamp': parts[6],
        };
      } else {
        return null;
      }

      final officerId =
          map['assignedOfficerId'] as String? ?? map['officerId'] as String? ?? '';

      return ActivityQrPayload(
        paroleeId: map['paroleeId'] as String? ?? '',
        paroleeName: map['paroleeName'] as String? ?? '',
        activityId: map['activityId'] as String? ?? '',
        assignedOfficerId: officerId,
        activityTitle: map['activityTitle'] as String? ?? '',
        token: map['token'] as String? ?? '',
        timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
