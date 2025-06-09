// lib/presentation/screens/gamification_screen.dart

// ADDED: The missing import that resolves most of the errors
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/presentation/providers/gamification_provider.dart';


class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final gamificationProvider = Provider.of<GamificationProvider>(context, listen: false);
      if (authProvider.isLoggedIn && authProvider.currentUserId != null) {
        gamificationProvider.loadAllData(authProvider.currentUserId!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // This is a placeholder build method. You will need to rebuild the full UI
    // for this screen based on your app's design. This just ensures no errors.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements & Rewards'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.trending_up), text: 'Progress'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Badges'),
            Tab(icon: Icon(Icons.redeem), text: 'Rewards'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          Center(child: Text('Progress Tab Content')),
          Center(child: Text('Badges Tab Content')),
          Center(child: Text('Rewards Tab Content')),
        ],
      ),
    );
  }
}