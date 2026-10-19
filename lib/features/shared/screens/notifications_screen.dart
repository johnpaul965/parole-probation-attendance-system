import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:last/core/services/notification_provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/widgets/empty_state.dart';
import 'package:last/core/widgets/loading_shimmer.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/shared/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = context.read<AuthProvider>().user?.id;
      if (id != null) context.read<NotificationProvider>().watch(id);
    });
  }

  IconData _icon(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return Icons.warning_amber_rounded;
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.reminder:
        return Icons.schedule;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  Color _color(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return AppColors.error;
      case NotificationType.success:
        return AppColors.success;
      case NotificationType.reminder:
        return AppColors.warning;
      case NotificationType.info:
        return AppColors.officer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notif = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: notif.isLoading && notif.items.isEmpty
          ? const LoadingShimmer()
          : notif.error != null && notif.items.isEmpty
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: notif.error!,
                  actionLabel: 'Retry',
                  onAction: () {
                    final id = context.read<AuthProvider>().user?.id;
                    if (id != null) context.read<NotificationProvider>().watch(id);
                  },
                )
              : notif.items.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none,
                      title: 'No notifications',
                      subtitle: 'You are all caught up',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notif.items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final n = notif.items[i];
                        return Dismissible(
                          key: ValueKey(n.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => context.read<NotificationProvider>().markRead(n.id),
                          child: Card(
                            color: n.read ? Colors.white : AppColors.officer.withValues(alpha: 0.04),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _color(n.type).withValues(alpha: 0.12),
                                child: Icon(_icon(n.type), color: _color(n.type), size: 20),
                              ),
                              title: Text(
                                n.title,
                                style: TextStyle(
                                  fontWeight: n.read ? FontWeight.w500 : FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.body, style: const TextStyle(fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM d, h:mm a').format(n.createdAt),
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              onTap: () => context.read<NotificationProvider>().markRead(n.id),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
