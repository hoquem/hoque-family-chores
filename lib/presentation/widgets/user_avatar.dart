import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../domain/entities/user.dart';

/// A member's avatar, resolved by precedence: chosen emoji → photo → initial.
///
/// One widget so every surface (profile, family list, greeting, task details)
/// shows the same thing when someone picks an emoji.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 20});

  final User user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final emoji = user.avatarEmoji;
    if (emoji != null && emoji.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        // Emoji scaled to the circle; a hair under the diameter so it doesn't
        // clip against the edge.
        child: Text(emoji, style: TextStyle(fontSize: radius * 1.1)),
      );
    }

    final photo = user.photoUrl;
    if (photo != null && photo.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(photo),
      );
    }

    return CircleAvatar(
      radius: radius,
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
        style: TextStyle(fontSize: radius * 0.8),
      ),
    );
  }
}

/// A small, deliberately curated set of kid-friendly avatar emojis. Not the
/// whole Unicode set — a family app doesn't need every emoji, and a fixed grid
/// keeps it friendly and predictable.
const List<String> kAvatarEmojis = [
  '🦊', '🐼', '🐵', '🦁', '🐯', '🐸', '🐰', '🐨',
  '🐷', '🐶', '🐱', '🦄', '🐢', '🐙', '🦋', '🐝',
  '⭐', '🌟', '🚀', '⚽', '🏀', '🎨', '🎸', '🍕',
  '🍦', '🍩', '🌈', '🔥', '😎', '🤩', '🦖', '👑',
];

/// Bottom sheet emoji picker. Returns the chosen emoji, an empty string to
/// clear back to the initial, or null if dismissed.
Future<String?> showAvatarEmojiPicker(
  BuildContext context, {
  String? current,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pick your avatar',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              GridView.count(
                key: const Key('avatar_emoji_grid'),
                crossAxisCount: 6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final emoji in kAvatarEmojis)
                    _EmojiCell(
                      emoji: emoji,
                      selected: emoji == current,
                      onTap: () => Navigator.of(context).pop(emoji),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('avatar_use_initial'),
                onPressed: () => Navigator.of(context).pop(''),
                icon: const Icon(Icons.abc),
                label: const Text('Use my initial instead'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _EmojiCell extends StatelessWidget {
  const _EmojiCell({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
      ),
    );
  }
}
