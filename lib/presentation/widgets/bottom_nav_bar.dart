import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    logger.d("[BottomNavBar] Building with current index: $currentIndex");

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        logger.i("[BottomNavBar] Navigation tapped: $index");
        onTap(index);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: context.tokens.inkMuted,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
        // Beside Tasks on purpose: you earn on the left, you spend on the
        // right. Stars bought nothing at all before this tab existed.
        BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard), label: 'Rewards'),
        BottomNavigationBarItem(icon: Icon(Icons.family_restroom), label: 'Family'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
