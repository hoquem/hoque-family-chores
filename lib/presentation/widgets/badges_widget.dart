import 'package:flutter/material.dart'
    hide Badge; // Hide Flutter's Badge widget to prevent ambiguity
import 'package:hoque_family_chores/models/badge.dart'; // Import your Badge model
import 'package:hoque_family_chores/models/enums.dart';

class BadgesWidget extends StatelessWidget {
  final List<Badge> badges;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const BadgesWidget({
    super.key,
    required this.badges,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error: $errorMessage',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 8.0),
                ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      );
    }

    if (badges.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16.0),
              Text(
                'No Badges Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Complete tasks to earn badges!',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 2.0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: badge.rarity.color.withOpacity(0.2),
              child: Icon(Icons.emoji_events, color: badge.rarity.color),
            ),
            title: Text(
              badge.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              badge.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Text(
              '${badge.requiredPoints} pts',
              style: TextStyle(
                color: badge.rarity.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
