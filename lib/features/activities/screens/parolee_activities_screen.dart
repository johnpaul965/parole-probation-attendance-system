import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/widgets/empty_state.dart';
import 'package:last/core/widgets/gradient_header.dart';
import 'package:last/core/widgets/loading_shimmer.dart';
import 'package:last/features/activities/models/activity_model.dart';
import 'package:last/features/activities/providers/activity_provider.dart';
import 'package:last/features/activities/widgets/activity_card.dart';
import 'package:last/features/auth/providers/auth_provider.dart';

class ParoleeActivitiesScreen extends StatefulWidget {
  const ParoleeActivitiesScreen({super.key});

  @override
  State<ParoleeActivitiesScreen> createState() => _ParoleeActivitiesScreenState();
}

class _ParoleeActivitiesScreenState extends State<ParoleeActivitiesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = context.read<AuthProvider>().user?.id;
      if (id != null) context.read<ActivityProvider>().listenForParolee(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final upcoming = provider.activities
        .where((a) => a.status == ActivityStatus.pending || a.status == ActivityStatus.ongoing)
        .toList();
    final past = provider.activities
        .where((a) => a.status == ActivityStatus.completed || a.status == ActivityStatus.missed)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: provider.isLoading && provider.activities.isEmpty
          ? const LoadingShimmer()
          : CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: GradientHeader(
                    color: AppColors.parolee,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                        SizedBox(height: 6),
                        Text('Community service & counseling schedules', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (provider.activities.isEmpty)
                        const EmptyState(
                          icon: Icons.event_available_outlined,
                          title: 'No activities assigned',
                          subtitle: 'Your supervising officer will assign community activities here.',
                        )
                      else ...[
                        if (upcoming.isNotEmpty) ...[
                          const Text('Upcoming', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ...upcoming.map(
                            (a) => ActivityCard(
                              activity: a,
                              subtitle: a.officerName != null
                                  ? 'Officer: ${a.officerName} · Show QR to officer'
                                  : 'Show QR to officer',
                              onTap: () => context.push('/parolee/activities/${a.id}', extra: a),
                            ),
                          ),
                        ],
                        if (past.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Timeline', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ...past.map(
                            (a) => ActivityCard(
                              activity: a,
                              onTap: () => context.push('/parolee/activities/${a.id}', extra: a),
                            ),
                          ),
                        ],
                      ],
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}
