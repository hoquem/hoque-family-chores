import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
// Import all screens that will be part of the bottom navigation
import 'package:hoque_family_chores/presentation/screens/home_screen.dart';
import 'package:hoque_family_chores/presentation/screens/task_list_screen.dart';
import 'package:hoque_family_chores/presentation/screens/family_list_screen.dart';
import 'package:hoque_family_chores/presentation/screens/gamification_screen.dart'; // Used as 'Progress'
import 'package:hoque_family_chores/presentation/screens/user_profile_screen.dart'; // For modal display
import 'package:hoque_family_chores/utils/logger.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _logger = AppLogger();
  int _selectedIndex = 0; // Set initial index to 0 for the Home tab

  // List of main content widgets for each tab
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(), // Index 0: Home screen
    const TaskListScreen(), // Index 1: Tasks
    const FamilyListScreen(), // Index 2: Family
    const GamificationScreen(), // Index 3: Progress/Gamification
  ];

  // Titles corresponding to each tab's AppBar
  static const List<String> _appBarTitles = <String>[
    'Home',
    'Tasks',
    'Family',
    'Progress',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]),
        actions: [
          // Show filter button only when Tasks tab is selected
          if (_selectedIndex == 1) // Tasks tab
            PopupMenuButton<TaskFilterType>(
              icon: const Icon(Icons.filter_list),
              onSelected: (filter) {
                _logger.d('AppShell: Setting task filter to $filter');
                // Set the filter using the task list notifier
                ref.read(taskListNotifierProvider.notifier).setFilter(filter);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: TaskFilterType.all,
                  child: Text('All Tasks'),
                ),
                const PopupMenuItem(
                  value: TaskFilterType.myTasks,
                  child: Text('My Tasks'),
                ),
                const PopupMenuItem(
                  value: TaskFilterType.available,
                  child: Text('Available Tasks'),
                ),
                const PopupMenuItem(
                  value: TaskFilterType.completed,
                  child: Text('Completed Tasks'),
                ),
              ],
            ),
          IconButton(
            icon: CircleAvatar(
              backgroundImage: currentUser?.photoUrl != null && currentUser!.photoUrl!.isNotEmpty
                  ? NetworkImage(currentUser.photoUrl!)
                  : null,
              child: currentUser?.photoUrl == null || currentUser!.photoUrl!.isEmpty
                  ? Text(
                      currentUser?.name.substring(0, 1).toUpperCase() ?? '',
                    )
                  : null,
            ),
            onPressed: () {
              _logger.i("Navigating to User Profile Screen (Modal).");
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
            tooltip: 'View Profile',
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
          BottomNavigationBarItem(
            icon: Icon(Icons.family_restroom),
            label: 'Family',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Progress',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
