import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/widgets/empty_state.dart';
import 'package:last/core/widgets/gradient_header.dart';
import 'package:last/core/widgets/loading_shimmer.dart';
import 'package:last/core/widgets/stat_card.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/tracking/providers/tracking_provider.dart';
import 'package:last/features/tracking/widgets/parolee_tracking_card.dart';
import 'package:last/features/officer/providers/dashboard_provider.dart';
import 'package:last/features/officer/widgets/live_attendance_panel.dart';
import 'package:last/features/officer/widgets/parolee_card.dart';
import 'package:last/features/shared/models/attendance_record.dart';
class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  final _searchController = TextEditingController();
  AttendanceStatus? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<TrackingProvider>().startWatchingAssigned(
              requester: user,
              officerId: user.id,
            );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final dash = context.watch<DashboardProvider>();
    final tracking = context.watch<TrackingProvider>();
    final stats = dash.stats;
    final live = dash.liveStats;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: dash.error != null && dash.parolees.isEmpty && !dash.isLoading
          ? EmptyState(
              icon: Icons.cloud_off,
              title: 'Dashboard unavailable',
              subtitle: dash.error,
              actionLabel: 'Retry',
              onAction: () {
                final id = context.read<AuthProvider>().user?.id;
                if (id != null) context.read<DashboardProvider>().refresh(id);
              },
            )
          : RefreshIndicator(
              onRefresh: () async {
                final id = context.read<AuthProvider>().user?.id;
                if (id != null) await context.read<DashboardProvider>().refresh(id);
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: GradientHeader(
                      color: AppColors.officer,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Good ${_greeting()},',
                                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)),
                                  ),
                                  Text(user.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                                ],
                              ),
                              CircleAvatar(
                                backgroundColor: Colors.white24,
                                child: Text(user.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (stats != null)
                            Row(
                              children: [
                                StatCard(
                                  label: 'Total Cases',
                                  value: '${stats.totalCases}',
                                  onTap: () {
                                    setState(() => _filter = null);
                                    context.read<DashboardProvider>().setFilter(null);
                                  },
                                ),
                                const SizedBox(width: 12),
                                StatCard(
                                  label: 'Checked-in',
                                  value: '${stats.checkedIn}',
                                  onTap: () {
                                    setState(() => _filter = AttendanceStatus.checkedIn);
                                    context.read<DashboardProvider>().setFilter(AttendanceStatus.checkedIn);
                                  },
                                ),
                                const SizedBox(width: 12),
                                StatCard(
                                  label: 'Pending',
                                  value: '${stats.pending}',
                                  onTap: () {
                                    setState(() => _filter = AttendanceStatus.pending);
                                    context.read<DashboardProvider>().setFilter(AttendanceStatus.pending);
                                  },
                                ),
                                const SizedBox(width: 12),
                                StatCard(
                                  label: 'Missed',
                                  value: '${stats.missed}',
                                  onTap: () {
                                    setState(() => _filter = AttendanceStatus.missed);
                                    context.read<DashboardProvider>().setFilter(AttendanceStatus.missed);
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search parolees...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    context.read<DashboardProvider>().setSearch('');
                                  },
                                )
                              : null,
                        ),
                        onSubmitted: (v) => context.read<DashboardProvider>().setSearch(v),
                      ),
                    ),
                  ),
                  if (live != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: LiveAttendancePanel(
                          totalCases: live.stats.totalCases,
                          checkedIn: live.stats.checkedIn,
                          pending: live.stats.pending,
                          missed: live.stats.missed,
                          checkedInList: live.checkedIn,
                          pendingList: live.pending,
                          missedList: live.missed,
                          lastUpdated: dash.lastUpdated,
                          onFilterTap: (status) {
                            setState(() => _filter = status);
                            context.read<DashboardProvider>().setFilter(status);
                          },
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All',
                              selected: _filter == null,
                              onTap: () {
                                setState(() => _filter = null);
                                context.read<DashboardProvider>().setFilter(null);
                              },
                            ),
                            ...AttendanceStatus.values.where((s) => s != AttendanceStatus.confirmed).map(
                                  (s) => _FilterChip(
                                    label: s.label,
                                    selected: _filter == s,
                                    onTap: () {
                                      setState(() => _filter = s);
                                      context.read<DashboardProvider>().setFilter(s);
                                    },
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (tracking.assignedParolees.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const _SectionLabel('Live Tracking'),
                                TextButton(
                                  onPressed: () => context.go('/officer/profile'),
                                  child: const Text('View All'),
                                ),
                              ],
                            ),
                            ...tracking.assignedParolees.take(2).map(
                                  (p) => ParoleeTrackingCard(
                                    summary: p,
                                    onTrack: () => context.push('/officer/parolees/${p.paroleeId}'),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  if (dash.schedules.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(Icons.event_note_outlined, color: AppColors.officer),
                                title: const Text('Activity Management', style: TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: const Text('Create & monitor community activities'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.go('/officer/activities'),
                              ),
                            ),
                            const _SectionLabel('Upcoming Schedules'),
                            ...dash.schedules.take(3).map(
                                  (s) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.event, color: AppColors.officer, size: 20),
                                      title: Text(s.paroleeName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      subtitle: Text(
                                        '${DateFormat('MMM d, y').format(s.scheduledAt)} · ${s.location}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      trailing: Text(s.type, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                    ),
                                  ),
                                ),
                            const _SectionLabel('Parolees'),
                          ],
                        ),
                      ),
                    ),
                  if (dash.isLoading && dash.parolees.isEmpty)
                    const SliverFillRemaining(child: LoadingShimmer())
                  else if (dash.parolees.isEmpty)
                    const SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.people_outline,
                        title: 'No parolees assigned',
                        subtitle: 'Assign parolees in user management',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => ParoleeCard(
                            parolee: dash.parolees[i],
                            onTap: () => context.push(
                              '/officer/parolees/${dash.parolees[i].id}',
                              extra: dash.parolees[i],
                            ),
                          ),
                          childCount: dash.parolees.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.officer.withValues(alpha: 0.15),
        checkmarkColor: AppColors.officer,
      ),
    );
  }
}
