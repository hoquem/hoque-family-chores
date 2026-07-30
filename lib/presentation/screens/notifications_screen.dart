import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/repositories/notification_repository.dart'
    as domain;
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/notifications_provider.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/motion/entrance_stagger.dart';

/// The user's notification inbox: newest first, grouped by day,
/// tap to mark read, swipe to delete, "Mark all as read" action.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (user != null)
            TextButton(
              onPressed: () async {
                final notifications =
                    await ref.read(getNotificationsUseCaseProvider).call(userId: user.id);
                notifications.fold(
                  (_) {},
                  (list) async {
                    for (final n in list.where((n) => !n.isRead)) {
                      await ref.read(markNotificationAsReadUseCaseProvider).call(
                            notificationId: n.id,
                          );
                    }
                  },
                );
              },
              child: Text(
                'Mark all read',
                style: TextStyle(color: context.tokens.ink),
              ),
            ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ref.watch(notificationsProvider(user.id)).when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('Could not load notifications: $error'),
                  ),
                ),
                data: (notifications) => notifications.isEmpty
                    ? _EmptyState()
                    : _NotificationList(
                        notifications: notifications,
                        userId: user.id.value,
                      ),
              ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 64, color: context.tokens.inkMuted),
          const SizedBox(height: 16),
          Text(
            "You're all caught up!",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.tokens.inkMuted,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'New notifications will appear here.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: context.tokens.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<domain.Notification> notifications;
  final String userId;

  const _NotificationList({
    required this.notifications,
    required this.userId,
  });

  static String _groupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    if (d.isAfter(today.subtract(const Duration(days: 7)))) {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[date.weekday - 1];
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Group by day.
    final groups = <String, List<domain.Notification>>{};
    for (final n in notifications) {
      final label = _groupLabel(n.createdAt);
      groups.putIfAbsent(label, () => []).add(n);
    }
    final labels = groups.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: labels.length,
      itemBuilder: (context, index) {
        final label = labels[index];
        final items = groups[label]!;
        return EntranceStagger(
          index: index,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: context.tokens.inkSoft,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ...items.asMap().entries.map((entry) => _NotificationTile(
                key: ValueKey(entry.value.id),
                notification: entry.value,
              )),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final domain.Notification notification;

  const _NotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: context.tokens.brickDeep,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: context.tokens.cream),
      ),
      onDismissed: (_) => ref
          .read(deleteNotificationUseCaseProvider)
          .call(notificationId: notification.id),
      child: ListTile(
        leading: _NotificationIcon(isRead: notification.isRead),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(notification.message),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: context.tokens.amberWarnDeep,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: notification.isRead
            ? null
            : () => ref
                .read(markNotificationAsReadUseCaseProvider)
                .call(notificationId: notification.id),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  final bool isRead;
  const _NotificationIcon({required this.isRead});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isRead
            ? context.tokens.inkMuted.withValues(alpha: 0.12)
            : context.tokens.amberWarn.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isRead ? Icons.notifications_none : Icons.notifications_active,
        size: 20,
        color: isRead ? context.tokens.inkMuted : context.tokens.amberWarnDeep,
      ),
    );
  }
}
