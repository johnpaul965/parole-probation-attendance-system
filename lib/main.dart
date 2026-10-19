import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:last/core/constants/app_constants.dart';
import 'package:last/core/services/notification_provider.dart';
import 'package:last/core/services/session_service.dart';
import 'package:last/core/theme/app_theme.dart';
import 'package:last/features/activities/providers/activity_attendance_provider.dart';
import 'package:last/features/activities/providers/activity_provider.dart';
import 'package:last/features/admin/providers/admin_provider.dart';
import 'package:last/features/officer/providers/officer_provider.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/officer/providers/dashboard_provider.dart';
import 'package:last/features/parolee/providers/attendance_provider.dart';
import 'package:last/features/parolee/providers/parolee_provider.dart';
import 'package:last/features/reports/providers/reports_provider.dart';
import 'package:last/core/utils/supabase_config.dart';
import 'package:last/features/tracking/providers/phone_location_provider.dart';
import 'package:last/features/tracking/providers/tracking_provider.dart';
import 'package:last/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await SessionService.init();
  runApp(const ParoleProbationApp());
}

class ParoleProbationApp extends StatefulWidget {
  const ParoleProbationApp({super.key});

  @override
  State<ParoleProbationApp> createState() => _ParoleProbationAppState();
}

class _ParoleProbationAppState extends State<ParoleProbationApp> {
  late final AuthProvider _authProvider;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider()..initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ParoleeProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => ActivityAttendanceProvider()),
        ChangeNotifierProvider(create: (_) => OfficerProvider()),
        ChangeNotifierProvider(create: (_) => TrackingProvider()),
        ChangeNotifierProvider(create: (_) => PhoneLocationProvider()),
      ],
      child: Builder(
        builder: (context) {
          _router ??= AppRouter.create(context);
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            routerConfig: _router!,
            builder: (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: const [
                Breakpoint(start: 0, end: 450, name: MOBILE),
                Breakpoint(start: 451, end: 800, name: TABLET),
                Breakpoint(start: 801, end: 1920, name: DESKTOP),
                Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
            ),
          );
        },
      ),
    );
  }
}
