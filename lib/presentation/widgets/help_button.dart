import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics.dart';
import '../providers/riverpod/auth_notifier.dart';
import '../providers/riverpod/help_hint_notifier.dart';

/// What one screen's help sheet says: a friendly title and a few plain-language
/// points. Written to be read by a child, not just a parent.
class HelpContent {
  const HelpContent({required this.title, required this.points});

  final String title;
  final List<String> points;
}

/// A `?` button for a screen's AppBar. Opens [content] in a bottom sheet.
///
/// Wears a small dot until the user has opened help anywhere (see
/// [HelpHintSeen]), so a first-timer notices it; after that it sits quietly.
class HelpButton extends ConsumerWidget {
  const HelpButton({super.key, required this.content});

  final HelpContent content;

  void _open(BuildContext context, WidgetRef ref) {
    ref.read(helpHintSeenProvider.notifier).markSeen();
    // Best-effort telemetry: reading auth or logging must never block help.
    try {
      final userId = ref.read(authNotifierProvider).user?.id.value;
      if (userId != null) {
        ref.read(analyticsProvider).log(
          AnalyticsEventName.helpOpened,
          userId: userId,
          params: {'screen': content.title},
        );
      }
    } catch (_) {/* telemetry is never fatal */}
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _HelpSheet(content: content),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = ref.watch(helpHintSeenProvider);
    final icon = IconButton(
      icon: const Icon(Icons.help_outline),
      tooltip: 'Help',
      onPressed: () => _open(context, ref),
    );
    // A quiet dot draws a first-timer's eye without a noisy animation.
    return seen ? icon : Badge(smallSize: 8, child: icon);
  }
}

class _HelpSheet extends StatelessWidget {
  const _HelpSheet({required this.content});

  final HelpContent content;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            for (final point in content.points)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: Theme.of(context).textTheme.bodyLarge),
                    Expanded(
                      child: Text(
                        point,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-screen help, written for kids and parents alike.
const kHomeHelp = HelpContent(
  title: 'Your home base 🏠',
  points: [
    "See today's missions and how many stars you've earned.",
    'Finish chores each day to keep your streak going.',
    'Tap a mission to jump in.',
  ],
);

const kTasksHelp = HelpContent(
  title: 'All the chores ✅',
  points: [
    "Every chore in your family lives here — yours and everyone else's.",
    'Tap the + button to add a new chore.',
    "Do a chore, mark it done, then someone else checks it off and you get your stars.",
  ],
);

const kRewardsHelp = HelpContent(
  title: 'Spend your stars 🎁',
  points: [
    'Turn stars into fun family things — a walk, a game, a treat.',
    'Anyone can add a treat. Tap + to suggest one.',
    'When you have enough stars, tap a treat to claim it.',
  ],
);

const kFamilyHelp = HelpContent(
  title: 'Your family 👨‍👩‍👧‍👦',
  points: [
    'See everyone in your family and how many stars they have.',
    'Share your invite code so others can join.',
    'You all help out and earn together.',
  ],
);

const kProfileHelp = HelpContent(
  title: 'Your profile 😊',
  points: [
    'Change your name and pick an emoji avatar.',
    'See your stars and your level.',
    'Manage notifications and sign out here.',
  ],
);
