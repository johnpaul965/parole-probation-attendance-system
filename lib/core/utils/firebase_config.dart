/// Firebase has been replaced with Supabase.
/// See [SupabaseConfig] in `lib/core/utils/supabase_config.dart`.
class FirebaseConfig {
  static bool get isConfigured => false;
  static bool get canUseFirestore => false;
}
