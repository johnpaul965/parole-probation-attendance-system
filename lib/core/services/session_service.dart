import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:last/features/auth/models/app_user.dart';

class SessionService {
  static const _userKey = 'session_user';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveUser(AppUser user) async {
    await _prefs?.setString(_userKey, jsonEncode(user.toMap()));
  }

  static AppUser? getUser() {
    final raw = _prefs?.getString(_userKey);
    if (raw == null) return null;
    return AppUser.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> clear() async {
    await _prefs?.remove(_userKey);
  }
}
