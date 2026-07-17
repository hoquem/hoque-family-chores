import 'package:flutter/material.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/services/home_stats.dart';
import 'package:hoque_family_chores/presentation/widgets/user_avatar.dart';

/// Friendly avatar + greeting row at the top of the Home screen.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final firstName = user.name.trim().split(' ').first;
    final level = levelFromPoints(user.points.value);

    return Row(
      children: [
        UserAvatar(user: user, radius: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi $firstName! 👋',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Level $level • ${user.points.value} ⭐',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
