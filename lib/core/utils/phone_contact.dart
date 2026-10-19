import 'package:url_launcher/url_launcher.dart';

class PhoneContact {
  PhoneContact._();

  static String? e164(String? raw) {
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'[\s-]'), '');
    if (RegExp(r'^09\d{9}$').hasMatch(digits)) {
      return '+63${digits.substring(1)}';
    }
    if (RegExp(r'^\+639\d{9}$').hasMatch(digits)) {
      return digits;
    }
    return null;
  }

  static Future<bool> call(String? raw) async {
    final number = e164(raw);
    if (number == null) return false;
    return launchUrl(Uri(scheme: 'tel', path: number));
  }

  static Future<bool> sms(String? raw) async {
    final number = e164(raw);
    if (number == null) return false;
    return launchUrl(Uri(scheme: 'sms', path: number));
  }
}
