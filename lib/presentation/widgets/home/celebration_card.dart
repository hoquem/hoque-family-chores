import 'package:flutter/material.dart';

/// Shown when every mission of the day is finished.
class CelebrationCard extends StatelessWidget {
  const CelebrationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: const Text('🎉', style: TextStyle(fontSize: 56)),
            ),
            const SizedBox(height: 12),
            Text(
              'All done for today! 🎉',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text('Amazing work!', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
