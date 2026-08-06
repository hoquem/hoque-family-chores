import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/bottom_nav_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/notifications_provider.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/family_screen.dart';
import 'package:hoque_family_chores/presentation/screens/home_screen.dart';
import 'package:hoque_family_chores/presentation/screens/rewards_screen.dart';
import 'package:hoque_family_chores/presentation/screens/task_list_screen.dart';
import 'package:hoque_family_chores/presentation/screens/user_profile_screen.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/presentation/motion/celebration_listener.dart';
import 'package:hoque_family_chores/presentation/widgets/bottom_nav_bar.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import '../../di/riverpod_container.dart';
import '../../data/repositories/firebase_push_notification_repository.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/presentation/utils/tab_badges.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    TaskListScreen(),
    RewardsScreen(),
    FamilyScreen(),
    UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Consume any deep link that arrived while the app was terminated.
    final pending = FirebasePushNotificationRepository.pendingDeepLink;
    if (pending != null) {
      FirebasePushNotificationRepository.pendingDeepLink = null;
      final uri = Uri.tryParse(pending);
      if (uri != null) {
        final host = uri.host;
        final nav = ref.read(bottomNavIndexNotifierProvider.notifier);
        switch (host) {
          case 'home':
            nav.setIndex(0);
            break;
          case 'tasks':
          case 'quest':
          case 'approvals':
            nav.setIndex(1);
            break;
          case 'rewards':
          case 'reward':
            nav.setIndex(2);
            break;
          case 'family':
            nav.setIndex(3);
            break;
          case 'profile':
            nav.setIndex(4);
            break;
          default:
            logger.w('[MainScreen] Unknown pending deep link host: $host');
        }
        logger.i('[MainScreen] Consumed pending deep link: $pending');
      }
    }

    final currentIndex = ref.watch(bottomNavIndexNotifierProvider);
    final user = ref.watch(authNotifierProvider).user;

    final badgeCounts = _computeBadgeCounts(ref, user);

    // Total actionable items across all tabs.
    final totalBadge = badgeCounts.values.fold(0, (sum, c) => sum + c);

    return Scaffold(
      body: Stack(
        children: [
          CelebrationListener(
            child: IndexedStack(index: currentIndex, children: _screens),
          ),
          // Invisible widget that syncs the platform app-icon badge count.
          _BadgeUpdater(count: totalBadge),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        badgeCounts: badgeCounts,
        onTap: (index) {
          logger.i("[MainScreen] Navigation item tapped: $index");
          ref.read(bottomNavIndexNotifierProvider.notifier).setIndex(index);
          try {
            const tabs = ['home', 'tasks', 'rewards', 'family', 'profile'];
            final userId = ref.read(authNotifierProvider).user?.id.value;
            if (userId != null && index >= 0 && index < tabs.length) {
              ref.read(analyticsProvider).log(
                AnalyticsEventName.screenViewed,
                userId: userId,
                params: {'tab': tabs[index]},
              );
            }
          } catch (_) {}
        },
      ),
    );
  }

  /// Watches what the badges need and hands it to [tabBadgeCounts], which owns
  /// the rules. This method only gathers; it decides nothing.
  Map<int, int> _computeBadgeCounts(WidgetRef ref, User? user) {
    if (user == null) return const {};

    final unread = ref.watch(notificationsProvider(user.id)).maybeWhen(
          data: (list) => list.where((n) => !n.isRead).length,
          orElse: () => 0,
        );
    final tasks = ref.watch(taskListStreamProvider(user.familyId)).maybeWhen(
          data: (list) => list,
          orElse: () => const <Task>[],
        );

    return tabBadgeCounts(
      viewer: user,
      tasks: tasks,
      unreadNotifications: unread,
    ).byTabIndex;
  }
}

/// Invisible widget that updates the platform app-icon badge count whenever
/// the computed total changes. Placed in the widget tree so it runs inside
/// the app lifecycle.
class _BadgeUpdater extends StatefulWidget {
  final int count;
  const _BadgeUpdater({required this.count});

  @override
  State<_BadgeUpdater> createState() => _BadgeUpdaterState();
}

class _BadgeUpdaterState extends State<_BadgeUpdater> {
  int? _lastCount;

  @override
  void didUpdateWidget(covariant _BadgeUpdater oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count) {
      _update();
    }
  }

  void _update() {
    // Debounce: only update when the count actually changes.
    if (_lastCount == widget.count) return;
    _lastCount = widget.count;
    // Best-effort: never block the UI for a badge update.
    try {
      final container = ProviderScope.containerOf(context);
      final repo = container.read(pushNotificationRepositoryProvider);
      repo.updateBadgeCount(widget.count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
