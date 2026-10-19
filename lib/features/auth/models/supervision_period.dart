enum SupervisionStatus {
  notSet,
  invalid,
  upcoming,
  active,
  completed,
  suspended,
}

class SupervisionSnapshot {
  const SupervisionSnapshot({
    required this.status,
    this.start,
    this.end,
    this.remainingDays,
  });

  final SupervisionStatus status;
  final DateTime? start;
  final DateTime? end;
  final int? remainingDays;

  bool get hasMissingDates =>
      status == SupervisionStatus.notSet || status == SupervisionStatus.invalid;

  String get label {
    switch (status) {
      case SupervisionStatus.notSet:
        return 'Not set';
      case SupervisionStatus.invalid:
        return 'Invalid dates';
      case SupervisionStatus.upcoming:
        return 'Upcoming';
      case SupervisionStatus.active:
        return 'Active';
      case SupervisionStatus.completed:
        return 'Completed (pending official confirmation)';
      case SupervisionStatus.suspended:
        return 'Suspended';
    }
  }

  String get shortLabel {
    switch (status) {
      case SupervisionStatus.completed:
        return 'Completed';
      default:
        return label;
    }
  }
}

class SupervisionPeriod {
  SupervisionPeriod._();

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String formatIso(DateTime date) {
    final d = dateOnly(date);
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  static DateTime? parseDate(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return dateOnly(raw);
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      final parsed = DateTime.tryParse(trimmed);
      if (parsed == null) return null;
      return dateOnly(parsed);
    }
    return null;
  }

  static String? supervisionRangeError(DateTime? start, DateTime? end) {
    if (start == null || end == null) return null;
    if (dateOnly(end).isBefore(dateOnly(start))) {
      return 'End date cannot be earlier than the start date';
    }
    return null;
  }

  static SupervisionSnapshot compute({
    String? startIso,
    String? endIso,
    Object? startRaw,
    Object? endRaw,
    bool isSuspended = false,
    DateTime? now,
  }) {
    final start = parseDate(startIso ?? startRaw);
    final end = parseDate(endIso ?? endRaw);
    final today = dateOnly(now ?? DateTime.now());

    if (isSuspended) {
      return SupervisionSnapshot(status: SupervisionStatus.suspended, start: start, end: end);
    }
    if (start == null || end == null) {
      return SupervisionSnapshot(status: SupervisionStatus.notSet, start: start, end: end);
    }
    if (end.isBefore(start)) {
      return SupervisionSnapshot(status: SupervisionStatus.invalid, start: start, end: end);
    }
    if (today.isBefore(start)) {
      return SupervisionSnapshot(status: SupervisionStatus.upcoming, start: start, end: end);
    }
    if (today.isAfter(end)) {
      return SupervisionSnapshot(status: SupervisionStatus.completed, start: start, end: end);
    }
    return SupervisionSnapshot(
      status: SupervisionStatus.active,
      start: start,
      end: end,
      remainingDays: end.difference(today).inDays,
    );
  }
}
