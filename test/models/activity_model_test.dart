import 'package:flutter_test/flutter_test.dart';
import 'package:last/features/activities/models/activity_model.dart';

void main() {
  group('ActivityType', () {
    test('fromString returns correct type', () {
      expect(ActivityType.fromString('treePlanting'), ActivityType.treePlanting);
      expect(ActivityType.fromString('communityCleanup'), ActivityType.communityCleanup);
    });

    test('fromString falls back to other for unknown', () {
      expect(ActivityType.fromString('invalid'), ActivityType.other);
    });

    test('label returns human-readable string', () {
      expect(ActivityType.treePlanting.label, 'Tree Planting');
      expect(ActivityType.communityCleanup.label, 'Community Clean-Up Drive');
      expect(ActivityType.counselingSession.label, 'Counseling Session');
    });
  });

  group('ActivityStatus', () {
    test('fromString returns correct status', () {
      expect(ActivityStatus.fromString('ongoing'), ActivityStatus.ongoing);
      expect(ActivityStatus.fromString('completed'), ActivityStatus.completed);
    });

    test('fromString falls back to pending for unknown', () {
      expect(ActivityStatus.fromString('xyz'), ActivityStatus.pending);
    });
  });

  group('ActivityModel', () {
    final now = DateTime(2026, 1, 15, 10, 30);
    final model = ActivityModel(
      id: 'act-1',
      title: 'Tree Planting Day',
      type: ActivityType.treePlanting,
      description: 'Plant trees in the park',
      location: 'City Park',
      scheduleDate: now,
      assignedParoleeIds: ['p1', 'p2', 'p3'],
      assignedOfficerId: 'off-1',
      status: ActivityStatus.ongoing,
      createdAt: now,
      completedParoleeIds: ['p1'],
      officerName: 'Officer Juan',
    );

    test('toMap and fromMap round-trip preserves data', () {
      final map = model.toMap();
      map['id'] = 'act-1';
      final restored = ActivityModel.fromMap(map);

      expect(restored.id, model.id);
      expect(restored.title, model.title);
      expect(restored.type, model.type);
      expect(restored.description, model.description);
      expect(restored.location, model.location);
      expect(restored.assignedOfficerId, model.assignedOfficerId);
      expect(restored.status, model.status);
      expect(restored.assignedParoleeIds, model.assignedParoleeIds);
      expect(restored.completedParoleeIds, model.completedParoleeIds);
      expect(restored.officerName, model.officerName);
    });

    test('computed properties are correct', () {
      expect(model.totalAssigned, 3);
      expect(model.totalCompleted, 1);
      expect(model.completionRate, closeTo(33.33, 0.01));
      expect(model.isAssignedTo('p1'), isTrue);
      expect(model.isAssignedTo('p4'), isFalse);
      expect(model.isCompletedBy('p1'), isTrue);
      expect(model.isCompletedBy('p2'), isFalse);
    });

    test('completionRate is 0 when no parolees assigned', () {
      final empty = model.copyWith(completedParoleeIds: []);
      expect(empty.completionRate, 0);
    });

    test('copyWith overrides specified fields', () {
      final updated = model.copyWith(status: ActivityStatus.completed);
      expect(updated.status, ActivityStatus.completed);
      expect(updated.title, model.title);
    });

    test('fromMap handles missing/null fields gracefully', () {
      final minimal = ActivityModel.fromMap({'id': 'x'});
      expect(minimal.id, 'x');
      expect(minimal.title, '');
      expect(minimal.type, ActivityType.other);
      expect(minimal.assignedParoleeIds, isEmpty);
    });
  });
}
