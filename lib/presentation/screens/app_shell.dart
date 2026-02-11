import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import all screens that will be part of the bottom navigation
import 'package:hoque_family_chores/presentation/screens/quest_board_screen.dart';
import 'package:hoque_family_chores/presentation/screens/gamification_screen.dart'; // Leaderboard
import 'package:hoque_family_chores/presentation/screens/family_list_screen.dart'; // Rewards (placeholder)
import 'package:hoque_family_chores/presentation/screens/user_profile_screen.dart';
import 'package:hoque_family_chores/presentation/widgets/quick_add_quest_sheet.dart';
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
    const QuestBoardScreen(), // Index 0: Quest Board
    const GamificationScreen(), // Index 1: Leaderboard
    const FamilyListScreen(), // Index 2: Rewards (placeholder)
    const UserProfileScreen(), // Index 3: Profile
  ];

  // Titles corresponding to each tab's AppBar
  static const List<String> _appBarTitles = <String>[
    'Quest Board',
    'Leaderboard',
    'Rewards',
    'Profile',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]),
        actions: [
          // Show settings icon only for non-profile tabs
          if (_selectedIndex != 3)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                _logger.i('AppShell: Settings tapped');
                // TODO: Navigate to settings
              },
              tooltip: 'Settings',
            ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                _logger.d('AppShell: Opening Quick Add Quest sheet');
                showQuickAddQuestSheet(context);
              },
              backgroundColor: const Color(0xFFFFB300),
              tooltip: 'Add Quest',
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Quest Board',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
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
