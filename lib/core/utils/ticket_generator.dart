import 'dart:math';

import 'package:last/core/constants/app_constants.dart';

class TicketGenerator {
  static final Random _random = Random();

  static String generate() {
    final seq = (_random.nextInt(9000) + 1000).toString();
    return '${AppConstants.ticketPrefix}-${AppConstants.ticketYear}-$seq';
  }

  static String? extractTicketId(String payload) {
    final trimmed = payload.trim();
    if (trimmed.startsWith(AppConstants.ticketPrefix)) return trimmed;
    final match = RegExp(r'[A-Z]{2}-\d{4}-\d{4}').firstMatch(trimmed);
    return match?.group(0);
  }
}
