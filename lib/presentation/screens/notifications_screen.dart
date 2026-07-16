import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/repositories/notification_repository.dart'
    as domain;
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/notifications_provider.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

/// The user's notification inbox: newest first, tap to mark read,
/// swipe to delete.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
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
                    ? const Center(
                        child: Text('No notifications yet'),
                      )
                    : ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) => _NotificationTile(
                          notification: notifications[index],
                        ),
                      ),
              ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final domain.Notification notification;

  const _NotificationTile({required this.notification});

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
        leading: Icon(
          notification.isRead
              ? Icons.notifications_none
              : Icons.notifications_active,
          color: notification.isRead ? context.tokens.inkMuted : context.tokens.amberWarn,
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(notification.message),
        onTap: notification.isRead
            ? null
            : () => ref
                .read(markNotificationAsReadUseCaseProvider)
                .call(notificationId: notification.id),
      ),
    );
  }
}
