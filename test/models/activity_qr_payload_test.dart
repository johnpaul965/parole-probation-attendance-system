import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:last/features/activities/models/activity_qr_payload.dart';

void main() {
  group('ActivityQrPayload', () {
    final payload = ActivityQrPayload(
      paroleeId: 'par-1',
      paroleeName: 'Juan Dela Cruz',
      activityId: 'act-1',
      assignedOfficerId: 'off-1',
      activityTitle: 'Tree Planting',
      token: 'tok-abc123',
      timestamp: DateTime(2026, 1, 15, 10, 30),
    );

    test('encode contains only opaque token and activity id', () {
      final encoded = payload.encode();
      final map = jsonDecode(encoded) as Map<String, dynamic>;
      expect(map.keys.toSet(), {'t', 'a'});
      expect(map['t'], 'tok-abc123');
      expect(map['a'], 'act-1');
      expect(encoded.contains('Juan'), isFalse);
      expect(encoded.contains('par-1'), isFalse);
    });

    test('decode recovers token and activity from compact encode', () {
      final encoded = payload.encode();
      final decoded = ActivityQrPayload.decode(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.token, payload.token);
      expect(decoded.activityId, payload.activityId);
      expect(decoded.paroleeId, isEmpty);
      expect(decoded.paroleeName, isEmpty);
    });

    test('decode handles legacy JSON with personal fields', () {
      final encoded = jsonEncode(payload.toJson());
      final decoded = ActivityQrPayload.decode(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.paroleeId, 'par-1');
      expect(decoded.paroleeName, 'Juan Dela Cruz');
      expect(decoded.token, 'tok-abc123');
    });

    test('decode handles legacy PPA_ACT format', () {
      const legacy =
          'PPA_ACT|par-1|Juan|act-1|off-1|tok-1|2026-01-15T10:30:00.000|Planting';
      final decoded = ActivityQrPayload.decode(legacy);
      expect(decoded, isNotNull);
      expect(decoded!.paroleeId, 'par-1');
      expect(decoded.assignedOfficerId, 'off-1');
      expect(decoded.activityTitle, 'Planting');
    });

    test('decode returns null for empty string', () {
      expect(ActivityQrPayload.decode(''), isNull);
      expect(ActivityQrPayload.decode('  '), isNull);
    });

    test('decode returns null for invalid format', () {
      expect(ActivityQrPayload.decode('random-text'), isNull);
      expect(ActivityQrPayload.decode('PPA_ACT|too|short'), isNull);
    });

    test('officerId alias matches assignedOfficerId', () {
      expect(payload.officerId, payload.assignedOfficerId);
    });
  });
}
