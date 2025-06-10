import 'package:flutter/material.dart' hide Badge; // Hide Flutter's Badge widget to prevent ambiguity
import 'package:hoque_family_chores/models/badge.dart'; // Import your Badge model
// import 'package:hoque_family_chores/models/enums.dart'; // <--- REMOVED UNUSED IMPORT

class BadgesWidget extends StatelessWidget {
  final List<Badge> badges;

  const BadgesWidget({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const Center(child: Text('No badges unlocked yet.'));
    }

    return ListView.builder(
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            leading: Icon(Icons.star, color: badge.rarity.color), // Using rarity color from enum
            title: Text(badge.name), // Corrected: Used badge.name
            subtitle: Text(badge.description),
          ),
        );
      },
    );
  }
}