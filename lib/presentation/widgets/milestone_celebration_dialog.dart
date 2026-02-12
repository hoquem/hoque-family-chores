import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/entities/streak.dart';

/// Milestone celebration dialog with confetti and rewards
class MilestoneCelebrationDialog extends StatefulWidget {
  final StreakMilestone milestone;
  final VoidCallback? onShare;

  const MilestoneCelebrationDialog({
    super.key,
    required this.milestone,
    this.onShare,
  });

  @override
  State<MilestoneCelebrationDialog> createState() =>
      _MilestoneCelebrationDialogState();
}

class _MilestoneCelebrationDialogState
    extends State<MilestoneCelebrationDialog>
    with TickerProviderStateMixin {
  late AnimationController _badgeController;
  late AnimationController _confettiController;
  late Animation<double> _badgeAnimation;

  @override
  void initState() {
    super.initState();
    
    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _badgeAnimation = CurvedAnimation(
      parent: _badgeController,
      curve: Curves.elasticOut,
    );

    // Start animations
    _confettiController.forward();
    _badgeController.forward();
  }

  @override
  void dispose() {
    _badgeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Simple confetti particles
          Positioned.fill(
            child: _SimpleConfetti(controller: _confettiController),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                
                // Sparkles
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('✨', style: TextStyle(fontSize: 32)),
                    SizedBox(width: 8),
                    Text('✨', style: TextStyle(fontSize: 32)),
                    SizedBox(width: 8),
                    Text('✨', style: TextStyle(fontSize: 32)),
                    SizedBox(width: 8),
                    Text('✨', style: TextStyle(fontSize: 32)),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Badge with bounce animation
                ScaleTransition(
                  scale: _badgeAnimation,
                  child: Text(
                    widget.milestone.badgeIcon,
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Title
                Text(
                  widget.milestone.title.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFB300),
                      ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  'You\'ve completed chores\nfor ${widget.milestone.days} days straight!',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Reward container
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        '+${widget.milestone.starReward} bonus stars added',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Amazing button
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'AMAZING!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Share option
                if (widget.onShare != null)
                  TextButton(
                    onPressed: widget.onShare,
                    child: const Text('Share with family'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show milestone celebration dialog
  static Future<void> show(
    BuildContext context,
    StreakMilestone milestone, {
    VoidCallback? onShare,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MilestoneCelebrationDialog(
        milestone: milestone,
        onShare: onShare,
      ),
    );
  }
}

/// Simple confetti animation widget
class _SimpleConfetti extends StatelessWidget {
  final AnimationController controller;

  const _SimpleConfetti({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ConfettiPainter(controller.value),
          child: Container(),
        );
      },
    );
  }
}

/// Custom painter for confetti particles
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final math.Random random = math.Random(42);

  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];

    // Generate 30 particles
    for (int i = 0; i < 30; i++) {
      final random = math.Random(i);
      final x = size.width * random.nextDouble();
      final y = -20 + (size.height * progress * (0.5 + random.nextDouble()));
      final rotation = progress * math.pi * 4 * random.nextDouble();
      
      paint.color = colors[i % colors.length].withValues(alpha: 1.0 - progress);
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      
      // Draw particle (small rectangle)
      canvas.drawRect(
        const Rect.fromLTWH(-4, -8, 8, 16),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
