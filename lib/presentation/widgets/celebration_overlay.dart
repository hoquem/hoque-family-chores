import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/celebration_providers.dart';

/// Type of celebration to display.
enum CelebrationType {
  questComplete,
  approval,
  levelUp,
  streakMilestone,
}

/// Reusable overlay widget that displays confetti animations.
/// 
/// Can be added to any screen to show celebrations. Automatically
/// respects reduced motion settings.
class CelebrationOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const CelebrationOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends ConsumerState<CelebrationOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  /// Triggers a celebration based on the type.
  void celebrate(CelebrationType type) {
    final reduceMotion = ref.read(reduceMotionEnabledProvider);
    
    if (reduceMotion || MediaQuery.of(context).disableAnimations) {
      // Skip confetti animation in reduced motion mode
      return;
    }

    // Configure confetti based on type
    switch (type) {
      case CelebrationType.questComplete:
        _confettiController.play();
        break;
      case CelebrationType.approval:
        _confettiController.play();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _confettiController.play();
        });
        break;
      case CelebrationType.levelUp:
        _confettiController.play();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _confettiController.play();
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _confettiController.play();
        });
        break;
      case CelebrationType.streakMilestone:
        _confettiController.play();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -3.14159 / 2, // Up
            emissionFrequency: 0.02,
            numberOfParticles: 50,
            gravity: 0.3,
            shouldLoop: false,
            colors: const [
              Color(0xFF6750A4), // Purple
              Color(0xFFFFB300), // Gold
              Color(0xFFB794F4), // Light Purple
              Color(0xFFFFD54F), // Light Gold
              Colors.white,
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget that shows confetti for a specific celebration type.
class ConfettiCelebration extends StatefulWidget {
  final CelebrationType type;
  final VoidCallback? onComplete;

  const ConfettiCelebration({
    super.key,
    required this.type,
    this.onComplete,
  });

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration> {
  late ConfettiController _controller;
  late int _particleCount;
  late Duration _duration;
  late int _blastCount;

  @override
  void initState() {
    super.initState();
    _configureForType();
    _controller = ConfettiController(duration: _duration);
    _triggerCelebration();
  }

  void _configureForType() {
    switch (widget.type) {
      case CelebrationType.questComplete:
        _particleCount = 50;
        _duration = const Duration(milliseconds: 800);
        _blastCount = 1;
        break;
      case CelebrationType.approval:
        _particleCount = 120;
        _duration = const Duration(milliseconds: 1500);
        _blastCount = 2;
        break;
      case CelebrationType.levelUp:
        _particleCount = 200;
        _duration = const Duration(milliseconds: 2500);
        _blastCount = 3;
        break;
      case CelebrationType.streakMilestone:
        _particleCount = 80;
        _duration = const Duration(milliseconds: 1200);
        _blastCount = 1;
        break;
    }
  }

  Future<void> _triggerCelebration() async {
    for (int i = 0; i < _blastCount; i++) {
      if (!mounted) return;
      _controller.play();
      if (i < _blastCount - 1) {
        await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
      }
    }

    // Auto-dismiss after animation completes
    final totalDuration = _duration.inMilliseconds + (1200 * _blastCount);
    await Future.delayed(Duration(milliseconds: totalDuration));
    if (mounted && widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiWidget(
      confettiController: _controller,
      blastDirection: -3.14159 / 2, // Up
      emissionFrequency: 0.02,
      numberOfParticles: _particleCount,
      gravity: 0.3,
      shouldLoop: false,
      colors: const [
        Color(0xFF6750A4), // Purple
        Color(0xFFFFB300), // Gold
        Color(0xFFB794F4), // Light Purple
        Color(0xFFFFD54F), // Light Gold
        Colors.white,
      ],
    );
  }
}

/// Simple celebration widget for reduced motion mode.
class SimpleCelebration extends StatefulWidget {
  final VoidCallback? onComplete;

  const SimpleCelebration({
    super.key,
    this.onComplete,
  });

  @override
  State<SimpleCelebration> createState() => _SimpleCelebrationState();
}

class _SimpleCelebrationState extends State<SimpleCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _controller.reverse().then((_) {
            if (widget.onComplete != null) {
              widget.onComplete!();
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: const Icon(
            Icons.check_circle,
            color: Color(0xFF4CAF50),
            size: 48,
          ),
        ),
      ),
    );
  }
}
