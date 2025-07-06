// lib/presentation/widgets/user_level_widget.dart
import 'package:flutter/material.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'dart:math' as math;

class UserLevelWidget extends StatefulWidget {
  final User user;
  final bool showLevelUpAnimation;
  final VoidCallback? onAnimationComplete;

  const UserLevelWidget({
    Key? key,
    required this.user,
    this.showLevelUpAnimation = false,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<UserLevelWidget> createState() => _UserLevelWidgetState();
}

class _UserLevelWidgetState extends State<UserLevelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _opacityAnimation;

  // Level calculation constants
  static const int _basePointsPerLevel = 100;
  static const double _pointsMultiplier = 1.5;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: _calculateProgressToNextLevel(),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.65, 0.85, curve: Curves.elasticOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.65, 0.85, curve: Curves.easeOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.85, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start the animation when the widget is first built
    _animationController.forward().then((_) {
      if (widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });
  }

  @override
  void didUpdateWidget(UserLevelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the level changed or we're showing the level up animation, restart the animation
    if (_calculateLevelFromPoints(oldWidget.user.points) !=
            _calculateLevelFromPoints(widget.user.points) ||
        widget.showLevelUpAnimation) {
      _animationController.reset();
      _progressAnimation = Tween<double>(
        begin: 0,
        end: _calculateProgressToNextLevel(),
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
        ),
      );
      _animationController.forward().then((_) {
        if (widget.onAnimationComplete != null) {
          widget.onAnimationComplete!();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Calculate user level from points
  int _calculateLevelFromPoints(Points points) {
    final totalPoints = points.value;
    int level = 0;
    int pointsNeeded = _basePointsPerLevel;
    
    while (totalPoints >= pointsNeeded) {
      totalPoints -= pointsNeeded;
      level++;
      pointsNeeded = (_basePointsPerLevel * math.pow(_pointsMultiplier, level)).round();
    }
    
    return level;
  }

  // Calculate points needed for next level
  int _calculatePointsNeededForNextLevel() {
    final currentLevel = _calculateLevelFromPoints(widget.user.points);
    return (_basePointsPerLevel * math.pow(_pointsMultiplier, currentLevel)).round();
  }

  // Calculate points in current level
  int _calculatePointsInCurrentLevel() {
    final totalPoints = widget.user.points.value;
    int level = 0;
    int pointsNeeded = _basePointsPerLevel;
    int pointsUsed = 0;
    
    while (totalPoints >= pointsNeeded) {
      totalPoints -= pointsNeeded;
      pointsUsed += pointsNeeded;
      level++;
      pointsNeeded = (_basePointsPerLevel * math.pow(_pointsMultiplier, level)).round();
    }
    
    return widget.user.points.value - pointsUsed;
  }

  // Calculate progress to next level (0.0 to 1.0)
  double _calculateProgressToNextLevel() {
    final pointsInCurrentLevel = _calculatePointsInCurrentLevel();
    final pointsNeededForNextLevel = _calculatePointsNeededForNextLevel();
    
    if (pointsNeededForNextLevel == 0) return 1.0;
    return pointsInCurrentLevel / pointsNeededForNextLevel;
  }

  // Get gradient colors based on user level
  List<Color> _getLevelGradient() {
    final level = _calculateLevelFromPoints(widget.user.points);
    switch (level) {
      case 0:
        return [Colors.grey.shade300, Colors.grey.shade500];
      case 1:
        return [Colors.green.shade300, Colors.green.shade700];
      case 2:
        return [Colors.blue.shade300, Colors.blue.shade700];
      case 3:
        return [Colors.purple.shade300, Colors.purple.shade700];
      case 4:
        return [Colors.orange.shade300, Colors.orange.shade700];
      default:
        if (level >= 5 && level < 10) {
          return [Colors.red.shade300, Colors.red.shade700];
        } else if (level >= 10 && level < 15) {
          return [Colors.pink.shade300, Colors.pink.shade700];
        } else {
          return [
            Color.fromARGB(255, 255, 215, 0), // Gold
            Color.fromARGB(255, 218, 165, 32), // Darker gold
          ];
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelGradient = _getLevelGradient();
    final level = _calculateLevelFromPoints(widget.user.points);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Level',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.user.points.value} points',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Animated level badge
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale:
                          widget.showLevelUpAnimation
                              ? _scaleAnimation.value
                              : 1.0,
                      child: Transform.rotate(
                        angle:
                            widget.showLevelUpAnimation
                                ? _rotateAnimation.value
                                : 0.0,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: levelGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withAlpha((255 * 0.1).round()),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$level',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getLevelTitle(level),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Animated progress bar
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  children: [
                                    // Background
                                    Container(
                                      height: 10,
                                      width: double.infinity,
                                      color: Colors.grey[300],
                                    ),
                                    // Progress
                                    Container(
                                      height: 10,
                                      width:
                                          MediaQuery.of(context).size.width *
                                          _progressAnimation.value *
                                          0.6, // Adjust for padding
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: levelGradient,
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_calculatePointsInCurrentLevel()} / ${_calculatePointsNeededForNextLevel()} points to next level',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Level up celebration
            if (widget.showLevelUpAnimation)
              AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: levelGradient[0].withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: levelGradient[1], width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.celebration, color: levelGradient[1]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Congratulations! You reached Level $level!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: levelGradient[1],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getLevelTitle(int level) {
    switch (level) {
      case 0:
        return 'Novice';
      case 1:
        return 'Apprentice';
      case 2:
        return 'Journeyman';
      case 3:
        return 'Expert';
      case 4:
        return 'Master';
      case 5:
        return 'Grand Master';
      case 6:
        return 'Legend';
      case 7:
        return 'Mythic';
      case 8:
        return 'Divine';
      case 9:
        return 'Immortal';
      default:
        return 'Godlike';
    }
  }
}
