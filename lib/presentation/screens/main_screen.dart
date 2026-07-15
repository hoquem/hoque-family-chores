import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/bottom_nav_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/home_screen.dart';
import 'package:hoque_family_chores/presentation/screens/task_list_screen.dart';
import 'package:hoque_family_chores/presentation/screens/family_screen.dart';
import 'package:hoque_family_chores/presentation/screens/user_profile_screen.dart';
import 'package:hoque_family_chores/presentation/widgets/bottom_nav_bar.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    // The full task manager (filters + add-task), not a read-only summary:
    // the Tasks tab is the only place tasks can be created and managed.
    TaskListScreen(),
    FamilyScreen(),
    UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tab selection lives in a provider so other screens (e.g. Home's
    // approval card) can switch tabs.
    final currentIndex = ref.watch(bottomNavIndexNotifierProvider);

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          logger.i("[MainScreen] Navigation item tapped: $index");
          ref.read(bottomNavIndexNotifierProvider.notifier).setIndex(index);
        },
      ),
    );
  }
}
