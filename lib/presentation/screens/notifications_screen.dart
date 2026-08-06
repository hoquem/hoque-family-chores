import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/repositories/notification_repository.dart'
    as domain;
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/notifications_provider.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/motion/entrance_stagger.dart';
import 'package:hoque_family_chores/presentation/widgets/notification_icon.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:dartz/dartz.dart' hide Task, State;
import 'package:hoque_family_chores/core/error/failures.dart';

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
                final messenger = ScaffoldMessenger.of(context);
                final tokens = context.tokens;
                final notifications = await ref
                    .read(getNotificationsUseCaseProvider)
                    .call(userId: user.id);
                // One message for the batch: a per-notification snackbar storm
                // is worse than silence.
                final failures = <String>[];
                await notifications.fold(
                  (failure) async => failures.add(failure.message),
                  (list) async {
                    for (final n in list.where((n) => !n.isRead)) {
                      final r = await ref
                          .read(markNotificationAsReadUseCaseProvider)
                          .call(userId: user.id, notificationId: n.id);
                      r.fold((f) => failures.add(f.message), (_) {});
                    }
                  },
                );
                if (failures.isNotEmpty) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                          "Couldn't mark them all read (${failures.first})"),
                      backgroundColor: tokens.brickDeep,
                    ),
                  );
                }
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

/// Runs a notification write and tells the user if it fails.
///
/// Every call site here used to discard the returned Either. When Firestore
/// refused the write, nothing surfaced: the unread dot stayed put and the only
/// evidence was a line in the device log. A write the user can see the result
/// of must report when it does not happen.
Future<void> _runAndReport(
  BuildContext context,
  Future<Either<Failure, Unit>> action,
  String whatFailed,
) async {
  // Captured before the await: this widget may be gone by the time it returns.
  final messenger = ScaffoldMessenger.of(context);
  final tokens = context.tokens;
  final result = await action;
  result.fold(
    (failure) => messenger.showSnackBar(
      SnackBar(
        content: Text('$whatFailed (${failure.message})'),
        backgroundColor: tokens.brickDeep,
      ),
    ),
    (_) {},
  );
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
                userId: userId,
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

  /// The signed-in user, and so the owner of every notification in this list.
  /// Reads and writes both address `users/{userId}/notifications/{id}`.
  final String userId;

  const _NotificationTile({
    super.key,
    required this.notification,
    required this.userId,
  });

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
      onDismissed: (_) => _runAndReport(
        context,
        ref.read(deleteNotificationUseCaseProvider).call(
            userId: UserId(userId), notificationId: notification.id),
        "Couldn't delete that notification",
      ),
      child: ListTile(
        leading: NotificationIcon(
          isRead: notification.isRead,
          type: notification.type,
          imageUrl: notification.imageUrl,
        ),
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
            : () => _runAndReport(
                  context,
                  ref.read(markNotificationAsReadUseCaseProvider).call(
                      userId: UserId(userId),
                      notificationId: notification.id),
                  "Couldn't mark that as read",
                ),
      ),
    );
  }
}

