import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/widgets/empty_state.dart';
import 'package:last/core/widgets/gradient_header.dart';
import 'package:last/core/widgets/loading_shimmer.dart';
import 'package:last/core/widgets/stat_card.dart';
import 'package:last/features/activities/models/activity_model.dart';
import 'package:last/features/activities/providers/activity_provider.dart';
import 'package:last/features/activities/widgets/activity_card.dart';
import 'package:last/features/auth/providers/auth_provider.dart';

class OfficerActivitiesScreen extends StatefulWidget {
  const OfficerActivitiesScreen({super.key});

  @override
  State<OfficerActivitiesScreen> createState() => _OfficerActivitiesScreenState();
}

class _OfficerActivitiesScreenState extends State<OfficerActivitiesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = context.read<AuthProvider>().user?.id;
      if (id != null) context.read<ActivityProvider>().listenForOfficer(id);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final stats = provider.stats;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/officer/activities/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Activity'),
        backgroundColor: AppColors.officer,
      ),
      body: provider.isLoading && provider.activities.isEmpty
          ? const LoadingShimmer()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: GradientHeader(
                    color: AppColors.officer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Activity Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            StatCard(label: 'Total', value: '${stats.total}'),
                            const SizedBox(width: 8),
                            StatCard(label: 'Ongoing', value: '${stats.ongoing}'),
                            const SizedBox(width: 8),
                            StatCard(label: 'Done', value: '${stats.completed}'),
                            const SizedBox(width: 8),
                            StatCard(label: 'Missed', value: '${stats.missed}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search activities...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        onChanged: provider.setSearch,
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: provider.statusFilter == null,
                              onSelected: (_) => provider.setStatusFilter(null),
                            ),
                            const SizedBox(width: 6),
                            ...ActivityStatus.values.map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  label: Text(s.label),
                                  selected: provider.statusFilter == s,
                                  onSelected: (_) => provider.setStatusFilter(s),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (provider.activities.isEmpty)
                        EmptyState(
                          icon: Icons.event_note_outlined,
                          title: provider.error ?? 'No activities yet',
                          subtitle: 'Create community service activities for your parolees.',
                          actionLabel: 'Create Activity',
                          onAction: () => context.push('/officer/activities/create'),
                        )
                      else
                        ...provider.activities.map(
                          (a) => ActivityCard(
                            activity: a,
                            onTap: () => context.push('/officer/activities/${a.id}', extra: a),
                            subtitle: a.status == ActivityStatus.ongoing ||
                                    a.status == ActivityStatus.pending
                                ? 'Tap to scan attendance QR'
                                : null,
                          ),
                        ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}
