import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/screens/home_screen.dart';
import 'package:hoque_family_chores/presentation/screens/task_list_screen.dart';
import 'package:hoque_family_chores/presentation/screens/family_screen.dart';
import 'package:hoque_family_chores/presentation/screens/user_profile_screen.dart';
import 'package:hoque_family_chores/presentation/widgets/bottom_nav_bar.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    // The full task manager (filters + add-task), not a read-only summary:
    // the Tasks tab is the only place tasks can be created and managed.
    const TaskListScreen(),
    const FamilyScreen(),
    const UserProfileScreen(),
  ];

  void _onNavItemTapped(int index) {
    logger.i("[MainScreen] Navigation item tapped: $index (from $_currentIndex)");
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }
}
