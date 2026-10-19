import 'package:last/core/utils/supabase_config.dart';
import 'package:last/features/tracking/services/supabase_tracking_repository.dart';
import 'package:last/features/tracking/services/mock_tracking_repository.dart';
import 'package:last/features/tracking/services/tracking_repository.dart';

TrackingRepository createTrackingRepository() {
  if (SupabaseConfig.isConfigured) {
    return SupabaseTrackingRepository();
  }
  return MockTrackingRepository();
}
