import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://iqltrfkyzbeepfpmsxci.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlxbHRyZmt5emJlZXBmcG1zeGNpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIyMTg1OTUsImV4cCI6MjEwNzc5NDU5NX0.aYfh--wAJP1Fua_VrqgXn5kKIaVE-jnK9ZqqVrBTgIU';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      debugPrint('[Supabase] Initialized successfully with $url');
    } catch (e, st) {
      debugPrint('[Supabase] Initialization error: $e\n$st');
    }
  }
}
