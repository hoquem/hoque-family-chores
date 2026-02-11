import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Dialog shown when a user's streak is broken
class StreakBrokenDialog extends StatefulWidget {
  final int previousStreak;
  final int longestStreak;

  const StreakBrokenDialog({
    super.key,
    required this.previousStreak,
    required this.longestStreak,
  });

  @override
  State<StreakBrokenDialog> createState() => _StreakBrokenDialogState();
}

class _StreakBrokenDialogState extends State<StreakBrokenDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<String> _motivationalMessages = [
    "Every champion was once a beginner who refused to give up.",
    "A setback is a setup for a comeback!",
    "Today is a new opportunity to build something great.",
    "Don't look back, you're not going that way!",
    "The best time to start is now!",
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _randomMessage {
    final random = math.Random();
    return _motivationalMessages[random.nextInt(_motivationalMessages.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),

            // Sad emoji with bounce
            ScaleTransition(
              scale: _scaleAnimation,
              child: const Text(
                '😢',
                style: TextStyle(fontSize: 64),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Your ${widget.previousStreak}-day streak ended',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Motivational quote card
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  '"$_randomMessage"',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Best streak display
            FadeTransition(
              opacity: _fadeAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    'Your best streak: ${widget.longestStreak} days',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFB300),
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Start fresh button
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: const Text(
                'START FRESH',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tip about freezes
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Buy streak freezes to protect your streak on busy days!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue.shade900,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show streak broken dialog
  static Future<void> show(
    BuildContext context,
    int previousStreak,
    int longestStreak,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreakBrokenDialog(
        previousStreak: previousStreak,
        longestStreak: longestStreak,
      ),
    );
  }
}
