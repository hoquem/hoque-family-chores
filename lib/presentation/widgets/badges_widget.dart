// lib/presentation/widgets/badges_widget.dart

import 'package:flutter/material.dart';
// MODIFIED: Imported your badge model with a prefix to avoid naming conflicts
import 'package:hoque_family_chores/models/badge.dart' as app_badge;
import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/models/user_profile.dart';

class BadgesWidget extends StatelessWidget {
  final UserProfile userProfile;
  // MODIFIED: Uses the prefixed name for your model
  final List<app_badge.Badge> allBadges;
  final List<app_badge.Badge> unlockedBadges;
  final bool showUnlockAnimation;
  final app_badge.Badge? newlyUnlockedBadge;

  const BadgesWidget({
    super.key,
    required this.userProfile,
    required this.allBadges,
    required this.unlockedBadges,
    this.showUnlockAnimation = false,
    this.newlyUnlockedBadge,
  });

  @override
  Widget build(BuildContext context) {
    final categories = BadgeCategory.values;

    return DefaultTabController(
      length: categories.length + 1, // +1 for the "All" tab
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: [
              const Tab(text: 'All'),
              ...categories.map((c) => Tab(text: c.displayName)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildBadgeGrid(allBadges),
                ...categories.map((c) {
                  final filteredBadges = allBadges.where((b) => b.category == c).toList();
                  return _buildBadgeGrid(filteredBadges);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MODIFIED: Uses the prefixed name for your model
  Widget _buildBadgeGrid(List<app_badge.Badge> badges) {
    if (badges.isEmpty) {
      return const Center(child: Text('No badges in this category.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final isUnlocked = unlockedBadges.any((ub) => ub.id == badge.id);
        return _buildBadgeIcon(badge, isUnlocked);
      },
    );
  }

  // MODIFIED: Uses the prefixed name for your model
  Widget _buildBadgeIcon(app_badge.Badge badge, bool isUnlocked) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.3,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: badge.rarity.color,
            child: Icon(Icons.star, color: Colors.white, size: 30), // Placeholder icon
          ),
          const SizedBox(height: 4),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}