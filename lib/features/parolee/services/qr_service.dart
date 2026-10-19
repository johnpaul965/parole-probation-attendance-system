import 'package:last/features/shared/models/attendance_record.dart';

class QrService {
  String buildPayload(AttendanceRecord record) {
    return record.qrPayload ??
        'PPA|${record.ticketId}|${record.paroleeId}|${record.checkInTime?.millisecondsSinceEpoch ?? 0}';
  }

  bool isValidFormat(String payload) {
    final parts = payload.split('|');
    return parts.length >= 3 && parts[0] == 'PPA';
  }

  String? extractTicketId(String payload) {
    if (!isValidFormat(payload)) return null;
    return payload.split('|')[1];
  }
}
