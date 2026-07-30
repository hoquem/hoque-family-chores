import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  /// Optional badge counts per tab index. A count > 0 renders a small badge.
  final Map<int, int> badgeCounts;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badgeCounts = const {},
  });

  @override
  Widget build(BuildContext context) {
    logger.d("[BottomNavBar] Building with current index: $currentIndex");

    Widget iconWithBadge(IconData icon, int index) {
      final count = badgeCounts[index] ?? 0;
      if (count <= 0) return Icon(icon);
      return Badge(
        label: Text(count > 99 ? '99+' : count.toString()),
        backgroundColor: context.tokens.brick,
        textColor: context.tokens.cream,
        child: Icon(icon),
      );
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        logger.i("[BottomNavBar] Navigation tapped: $index");
        onTap(index);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: context.tokens.inkMuted,
      items: [
        BottomNavigationBarItem(icon: iconWithBadge(Icons.home, 0), label: 'Home'),
        BottomNavigationBarItem(icon: iconWithBadge(Icons.task, 1), label: 'Tasks'),
        // Beside Tasks on purpose: you earn on the left, you spend on the
        // right. Stars bought nothing at all before this tab existed.
        BottomNavigationBarItem(
            icon: iconWithBadge(Icons.card_giftcard, 2), label: 'Treats'),
        BottomNavigationBarItem(icon: iconWithBadge(Icons.family_restroom, 3), label: 'Family'),
        BottomNavigationBarItem(icon: iconWithBadge(Icons.person, 4), label: 'Profile'),
      ],
    );
  }
}
