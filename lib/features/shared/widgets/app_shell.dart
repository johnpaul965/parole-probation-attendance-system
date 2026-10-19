import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ShellTab {
  const ShellTab({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.tabs,
    required this.roleColor,
    this.sidebarRoutes,
  });

  final Widget child;
  final List<ShellTab> tabs;
  final Color roleColor;
  final List<ShellTab>? sidebarRoutes;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (var i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    final index = _currentIndex(context);

    if (isDesktop) {
      final items = sidebarRoutes ?? tabs;
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: true,
              minExtendedWidth: 200,
              backgroundColor: Colors.white,
              selectedIndex: index.clamp(0, items.length - 1),
              onDestinationSelected: (i) => context.go(items[i].route),
              labelType: NavigationRailLabelType.none,
              selectedIconTheme: IconThemeData(color: roleColor),
              selectedLabelTextStyle: TextStyle(color: roleColor, fontWeight: FontWeight.w600),
              destinations: items
                  .map((t) => NavigationRailDestination(
                        icon: Icon(t.icon),
                        label: Text(t.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(tabs[i].route),
        destinations: tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

List<ShellTab> officerTabs(String base) => [
      ShellTab(label: 'Home', icon: Icons.dashboard_outlined, route: '$base/dashboard'),
      ShellTab(label: 'Users', icon: Icons.people_outline, route: '$base/users'),
      ShellTab(label: 'Trackers', icon: Icons.gps_fixed, route: '$base/trackers'),
      ShellTab(label: 'Activities', icon: Icons.event_note_outlined, route: '$base/activities'),
      ShellTab(label: 'Profile', icon: Icons.person_outline, route: '$base/profile'),
    ];

List<ShellTab> paroleeTabs(String base) => [
      ShellTab(label: 'Home', icon: Icons.home_outlined, route: '$base/dashboard'),
      ShellTab(label: 'Activities', icon: Icons.event_available_outlined, route: '$base/activities'),
      ShellTab(label: 'Check-in', icon: Icons.fact_check_outlined, route: '$base/check-in'),
      ShellTab(label: 'Alerts', icon: Icons.notifications_outlined, route: '$base/notifications'),
      ShellTab(label: 'Profile', icon: Icons.person_outline, route: '$base/profile'),
    ];

Color roleColor(UserRole role) {
  switch (role) {
    case UserRole.officer:
      return AppColors.officer;
    case UserRole.parolee:
      return AppColors.parolee;
  }
}
