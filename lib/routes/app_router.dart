import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:last/features/admin/screens/user_management_screen.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/auth/screens/login_screen.dart';
import 'package:last/features/auth/screens/register_screen.dart';
import 'package:last/features/auth/screens/splash_screen.dart';
import 'package:last/features/officer/screens/parolee_profile_screen.dart';
import 'package:last/features/officer/screens/officer_dashboard_screen.dart';
import 'package:last/features/officer/screens/qr_scanner_screen.dart';
import 'package:last/features/officer/widgets/officer_realtime_scope.dart';
import 'package:last/features/parolee/screens/attendance_history_screen.dart';
import 'package:last/features/parolee/screens/check_in_screen.dart';
import 'package:last/features/parolee/screens/parolee_dashboard_screen.dart';
import 'package:last/features/reports/screens/reports_screen.dart';
import 'package:last/features/shared/screens/notifications_screen.dart';
import 'package:last/features/officer/screens/officer_profile_screen.dart';
import 'package:last/features/activities/models/activity_model.dart';
import 'package:last/features/activities/screens/activity_attendance_scanner_screen.dart';
import 'package:last/features/activities/screens/activity_create_screen.dart';
import 'package:last/features/activities/screens/activity_detail_screen.dart';
import 'package:last/features/activities/screens/officer_activities_screen.dart';
import 'package:last/features/activities/screens/parolee_activities_screen.dart';
import 'package:last/features/officer/models/parolee_summary.dart';
import 'package:last/features/tracking/screens/device_detail_screen.dart';
import 'package:last/features/tracking/screens/live_tracking_screen.dart';
import 'package:last/features/tracking/screens/location_history_screen.dart';
import 'package:last/features/tracking/screens/tracker_management_screen.dart';
import 'package:last/features/shared/screens/profile_screen.dart';
import 'package:last/features/shared/widgets/app_shell.dart';

class AppRouter {
  static GoRouter create(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return GoRouter(
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.isAuthenticated;
        final path = state.matchedLocation;
        final isAuthRoute = path == '/' || path == '/login' || path == '/register';

        if (auth.isInitializing) {
          return path == '/' ? null : '/';
        }

        if (!loggedIn && !isAuthRoute) return '/login';
        if (loggedIn && (path == '/' || path == '/login' || path == '/register')) {
          return '${auth.user!.role.routePrefix}/dashboard';
        }
        if (loggedIn) {
          final prefix = auth.user!.role.routePrefix;
          if (path.startsWith('/officer') && auth.user!.role != UserRole.officer) {
            return '$prefix/dashboard';
          }
          if (path.startsWith('/parolee') && auth.user!.role != UserRole.parolee) {
            return '$prefix/dashboard';
          }
          if (path.startsWith('/admin')) {
            return '$prefix/dashboard';
          }
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/login',
          builder: (_, state) => LoginScreen(
            initialOfficer: state.uri.queryParameters['staff'] == '1',
          ),
        ),
        GoRoute(
          path: '/register',
          builder: (_, state) {
            final extra = state.extra;
            return RegisterScreen(
              role: extra is UserRole ? extra : UserRole.parolee,
            );
          },
        ),
        ShellRoute(
          builder: (context, state, child) => OfficerRealtimeScope(
            child: AppShell(
              roleColor: roleColor(UserRole.officer),
              tabs: officerTabs('/officer'),
              child: child,
            ),
          ),
          routes: [
            GoRoute(path: '/officer/dashboard', builder: (context, state) => const OfficerDashboardScreen()),
            GoRoute(path: '/officer/users', builder: (context, state) => const UserManagementScreen()),
            GoRoute(path: '/officer/trackers', builder: (context, state) => const TrackerManagementScreen()),
            GoRoute(
              path: '/officer/trackers/:trackerId',
              builder: (_, state) => DeviceDetailScreen(trackerId: state.pathParameters['trackerId']!),
            ),
            GoRoute(path: '/officer/reports', builder: (context, state) => const ReportsScreen()),
            GoRoute(path: '/officer/activities', builder: (context, state) => const OfficerActivitiesScreen()),
            GoRoute(path: '/officer/activities/create', builder: (context, state) => const ActivityCreateScreen()),
            GoRoute(
              path: '/officer/activities/:id',
              builder: (context, state) {
                final activity = state.extra as ActivityModel?;
                if (activity == null) {
                  return const Scaffold(body: Center(child: Text('Activity not found')));
                }
                return ActivityDetailScreen(activity: activity);
              },
            ),
            GoRoute(
              path: '/officer/activities/:id/scan',
              builder: (context, state) {
                final activity = state.extra as ActivityModel?;
                if (activity == null) {
                  return const Scaffold(body: Center(child: Text('Activity not found')));
                }
                return ActivityAttendanceScannerScreen(activity: activity);
              },
            ),
            GoRoute(path: '/officer/scan', builder: (context, state) => const QrScannerScreen()),
            GoRoute(path: '/officer/tracking', redirect: (context, state) => '/officer/profile'),
            GoRoute(
              path: '/officer/parolees/:paroleeId',
              builder: (context, state) {
                final summary = state.extra as ParoleeSummary?;
                return ParoleeProfileScreen(
                  paroleeId: state.pathParameters['paroleeId']!,
                  paroleeSummary: summary,
                );
              },
            ),
            GoRoute(
              path: '/officer/parolees/:paroleeId/live',
              builder: (_, state) => LiveTrackingScreen(paroleeId: state.pathParameters['paroleeId']!),
            ),
            GoRoute(
              path: '/officer/parolees/:paroleeId/history',
              builder: (_, state) => LocationHistoryScreen(paroleeId: state.pathParameters['paroleeId']!),
            ),
            GoRoute(
              path: '/officer/tracking/:paroleeId',
              redirect: (_, state) => '/officer/parolees/${state.pathParameters['paroleeId']}',
            ),
            GoRoute(
              path: '/officer/tracking/:paroleeId/history',
              redirect: (_, state) => '/officer/parolees/${state.pathParameters['paroleeId']}/history',
            ),
            GoRoute(path: '/officer/notifications', builder: (context, state) => const NotificationsScreen()),
            GoRoute(path: '/officer/profile', builder: (context, state) => const OfficerProfileScreen()),
          ],
        ),
        ShellRoute(
          builder: (context, state, child) => AppShell(
            roleColor: roleColor(UserRole.parolee),
            tabs: paroleeTabs('/parolee'),
            child: child,
          ),
          routes: [
            GoRoute(path: '/parolee/dashboard', builder: (context, state) => const ParoleeDashboardScreen()),
            GoRoute(path: '/parolee/activities', builder: (context, state) => const ParoleeActivitiesScreen()),
            GoRoute(
              path: '/parolee/activities/:id',
              builder: (context, state) {
                final activity = state.extra as ActivityModel?;
                if (activity == null) {
                  return const Scaffold(body: Center(child: Text('Activity not found')));
                }
                return ActivityDetailScreen(activity: activity);
              },
            ),
            GoRoute(path: '/parolee/check-in', builder: (context, state) => const CheckInScreen()),
            GoRoute(path: '/parolee/history', builder: (context, state) => const AttendanceHistoryScreen()),
            GoRoute(path: '/parolee/notifications', builder: (context, state) => const NotificationsScreen()),
            GoRoute(path: '/parolee/profile', builder: (context, state) => const ProfileScreen()),
          ],
        ),
      ],
    );
  }
}
