import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/screens/home_screen.dart';
import 'package:hoque_family_chores/presentation/screens/tasks_screen.dart';
import 'package:hoque_family_chores/presentation/screens/family_screen.dart';
import 'package:hoque_family_chores/presentation/screens/progress_screen.dart';
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
    const TasksScreen(),
    const FamilyScreen(),
    const ProgressScreen(),
  ];

  void _onNavItemTapped(int index) {
    logger.i("[MainScreen] Navigation item tapped: $index (from $_currentIndex)");
    setState(() {
      _currentIndex = index;
    });
    logger.d("[MainScreen] Navigation state updated to index: $_currentIndex");
  }

  @override
  Widget build(BuildContext context) {
    logger.d("[MainScreen] Building screen with current index: $_currentIndex");
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }
}
