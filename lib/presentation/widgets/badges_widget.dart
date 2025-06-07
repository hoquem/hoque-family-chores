// lib/presentation/widgets/badges_widget.dart
import 'package:flutter/material.dart';
import 'package:hoque_family_chores/models/badge.dart' as app_badge;
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/services/gamification_service.dart';
import 'package:provider/provider.dart';

class BadgesWidget extends StatefulWidget {
  final UserProfile userProfile;
  final List<app_badge.Badge> allBadges;
  final List<app_badge.Badge> unlockedBadges;
  final Function(app_badge.Badge)? onBadgeTap;
  final bool showUnlockAnimation;
  final app_badge.Badge? newlyUnlockedBadge;

  const BadgesWidget({
    Key? key,
    required this.userProfile,
    required this.allBadges,
    required this.unlockedBadges,
    this.onBadgeTap,
    this.showUnlockAnimation = false,
    this.newlyUnlockedBadge,
  }) : super(key: key);

  @override
  State<BadgesWidget> createState() => _BadgesWidgetState();
}

class _BadgesWidgetState extends State<BadgesWidget> with TickerProviderStateMixin {
  app_badge.BadgeCategory? _selectedCategory;
  late AnimationController _gridAnimationController;
  late AnimationController _unlockAnimationController;
  late Animation<double> _unlockScaleAnimation;
  late Animation<double> _unlockRotateAnimation;
  late Animation<double> _unlockShineAnimation;
  
  final List<AnimationController> _itemAnimationControllers = [];
  final List<Animation<double>> _itemAnimations = [];
  final GlobalKey _newBadgeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    
    // Grid animation controller
    _gridAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Unlock animation controller
    _unlockAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _unlockScaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _unlockAnimationController,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );
    
    _unlockRotateAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _unlockAnimationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );
    
    _unlockShineAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _unlockAnimationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeInOut),
      ),
    );
    
    // Start grid animation
    _gridAnimationController.forward();
    
    // If showing unlock animation, start it
    if (widget.showUnlockAnimation && widget.newlyUnlockedBadge != null) {
      _unlockAnimationController.forward();
    }
    
    // Initialize item animations after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeItemAnimations();
    });
  }
  
  void _initializeItemAnimations() {
    // Clear previous controllers
    for (var controller in _itemAnimationControllers) {
      controller.dispose();
    }
    _itemAnimationControllers.clear();
    _itemAnimations.clear();
    
    // Create new controllers for each badge
    final filteredBadges = _getFilteredBadges();
    for (int i = 0; i < filteredBadges.length; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );
      
      _itemAnimationControllers.add(controller);
      _itemAnimations.add(animation);
      
      // Stagger the animations
      Future.delayed(Duration(milliseconds: 50 * i), () {
        if (mounted) {
          controller.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(BadgesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If badges changed, reinitialize animations
    if (oldWidget.allBadges.length != widget.allBadges.length ||
        oldWidget.unlockedBadges.length != widget.unlockedBadges.length) {
      _initializeItemAnimations();
    }
    
    // If showing new unlock animation
    if (widget.showUnlockAnimation && 
        widget.newlyUnlockedBadge != null && 
        (oldWidget.newlyUnlockedBadge?.id != widget.newlyUnlockedBadge?.id)) {
      _unlockAnimationController.reset();
      _unlockAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _gridAnimationController.dispose();
    _unlockAnimationController.dispose();
    for (var controller in _itemAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<app_badge.Badge> _getFilteredBadges() {
    if (_selectedCategory == null) {
      return widget.allBadges;
    }
    return widget.allBadges
        .where((badge) => (badge as app_badge.Badge).category == _selectedCategory)
        .toList().cast<app_badge.Badge>();
  }

  bool _isBadgeUnlocked(app_badge.Badge badge) {
    return widget.unlockedBadges.any((b) => (b as app_badge.Badge).id == badge.id);
  }

  // Calculate progress percentage for a badge (0-100)
  int _getBadgeProgress(app_badge.Badge badge) {
    // For task master badges
    if (badge.category == app_badge.BadgeCategory.taskMaster) {
      final tasksCompleted = widget.userProfile.completedTasks;
      int requiredTasks = 0;
      
      switch (badge.id) {
        case 'task_master_1': requiredTasks = 5; break;
        case 'task_master_2': requiredTasks = 15; break;
        case 'task_master_3': requiredTasks = 30; break;
        case 'task_master_4': requiredTasks = 50; break;
        case 'task_master_5': requiredTasks = 100; break;
      }
      
      if (requiredTasks == 0) return 0;
      return (tasksCompleted / requiredTasks * 100).clamp(0, 100).toInt();
    }
    
    // For streaker badges
    if (badge.category == app_badge.BadgeCategory.streaker) {
      final currentStreak = widget.userProfile.currentStreak;
      int requiredStreak = 0;
      
      switch (badge.id) {
        case 'streaker_1': requiredStreak = 2; break;
        case 'streaker_2': requiredStreak = 7; break;
        case 'streaker_3': requiredStreak = 30; break;
      }
      
      if (requiredStreak == 0) return 0;
      return (currentStreak / requiredStreak * 100).clamp(0, 100).toInt();
    }
    
    // For points-based badges
    return (widget.userProfile.totalPoints / badge.requiredPoints * 100).clamp(0, 100).toInt();
  }

  // Get badge unlock date if available
  String _getBadgeUnlockDate(app_badge.Badge badge) {
    final unlockedBadge = widget.unlockedBadges.firstWhere(
      (b) => (b as app_badge.Badge).id == badge.id,
      orElse: () => badge,
    ) as app_badge.Badge;
    
    if (unlockedBadge.unlockedAt != null) {
      return '${unlockedBadge.unlockedAt!.day}/${unlockedBadge.unlockedAt!.month}/${unlockedBadge.unlockedAt!.year}';
    }
    return 'Not unlocked yet';
  }

  @override
  Widget build(BuildContext context) {
    final filteredBadges = _getFilteredBadges();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = null;
                      _initializeItemAnimations();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...app_badge.BadgeCategory.values.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(category.displayName),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                          _initializeItemAnimations();
                        });
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Progress summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                'Badges: ${widget.unlockedBadges.length}/${widget.allBadges.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                'Progress: ${(widget.unlockedBadges.length / widget.allBadges.length * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Badges grid
        Expanded(
          child: AnimatedBuilder(
            animation: _gridAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _gridAnimationController.value,
                child: child,
              );
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredBadges.length,
              itemBuilder: (context, index) {
                final badge = filteredBadges[index] as app_badge.Badge;
                final isUnlocked = _isBadgeUnlocked(badge);
                final progress = _getBadgeProgress(badge);
                final isNewlyUnlocked = widget.newlyUnlockedBadge?.id == badge.id;
                
                // Use item animation if available
                Widget badgeItem = _buildBadgeItem(badge, isUnlocked, progress);
                if (index < _itemAnimations.length) {
                  badgeItem = AnimatedBuilder(
                    animation: _itemAnimations[index],
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _itemAnimations[index].value,
                        child: Opacity(
                          opacity: _itemAnimations[index].value,
                          child: child,
                        ),
                      );
                    },
                    child: badgeItem,
                  );
                }
                
                // Apply unlock animation if this is the newly unlocked badge
                if (isNewlyUnlocked && widget.showUnlockAnimation) {
                  return AnimatedBuilder(
                    animation: _unlockAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _unlockScaleAnimation.value,
                        child: Transform.rotate(
                          angle: _unlockRotateAnimation.value,
                          child: Stack(
                            key: _newBadgeKey,
                            children: [
                              child!,
                              // Shine effect
                              Positioned.fill(
                                child: ClipRect(
                                  child: Transform.translate(
                                    offset: Offset(
                                      _unlockShineAnimation.value * 100,
                                      0,
                                    ),
                                    child: Container(
                                      width: 20,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0),
                                            Colors.white.withOpacity(0.5),
                                            Colors.white.withOpacity(0),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: badgeItem,
                  );
                }
                
                return badgeItem;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeItem(app_badge.Badge badge, bool isUnlocked, int progress) {
    final borderColor = isUnlocked ? badge.rarity.color : Colors.grey.shade300;
    final backgroundColor = isUnlocked 
        ? Color(int.parse(badge.color.replaceFirst('#', '0xff')))
        : Colors.grey.shade200;
    
    return GestureDetector(
      onTap: () {
        if (widget.onBadgeTap != null) {
          widget.onBadgeTap!(badge);
        } else {
          _showBadgeDetails(context, badge, isUnlocked);
        }
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: 3,
                ),
                boxShadow: isUnlocked ? [
                  BoxShadow(
                    color: borderColor.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ] : null,
              ),
              child: Center(
                child: Opacity(
                  opacity: isUnlocked ? 1.0 : 0.5,
                  child: Icon(
                    _getBadgeIcon(badge.iconName),
                    size: 36,
                    color: isUnlocked ? Colors.white : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
              color: isUnlocked ? Colors.black : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          // Progress indicator for locked badges
          if (!isUnlocked && progress > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 4,
                width: 60,
                child: LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    badge.rarity.color.withOpacity(0.7),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showBadgeDetails(BuildContext context, app_badge.Badge badge, bool isUnlocked) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.8,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // Badge header with icon
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isUnlocked 
                              ? Color(int.parse(badge.color.replaceFirst('#', '0xff')))
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isUnlocked ? badge.rarity.color : Colors.grey.shade300,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _getBadgeIcon(badge.iconName),
                            size: 32,
                            color: isUnlocked ? Colors.white : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              badge.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badge.rarity.color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    badge.rarity.displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: badge.rarity.color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    badge.category.displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Badge description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.description,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Badge status
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isUnlocked ? Icons.check_circle : Icons.lock,
                        color: isUnlocked ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isUnlocked 
                            ? 'Unlocked on ${_getBadgeUnlockDate(badge)}' 
                            : 'Locked - ${badge.requiredPoints} points required',
                        style: TextStyle(
                          fontSize: 16,
                          color: isUnlocked ? Colors.green : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress
                  if (!isUnlocked)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _getBadgeProgress(badge) / 100,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              badge.rarity.color,
                            ),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_getBadgeProgress(badge)}% Complete',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Close button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUnlocked 
                          ? badge.rarity.color
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to get icon based on badge name
  IconData _getBadgeIcon(String iconName) {
    switch (iconName) {
      case 'task_beginner': return Icons.assignment_outlined;
      case 'task_apprentice': return Icons.assignment;
      case 'task_expert': return Icons.assignment_turned_in_outlined;
      case 'task_master': return Icons.assignment_turned_in;
      case 'task_legend': return Icons.workspace_premium;
      case 'weekend_warrior': return Icons.weekend;
      case 'week_warrior': return Icons.calendar_view_week;
      case 'month_warrior': return Icons.calendar_month;
      case 'helping_hand': return Icons.handshake;
      case 'super_helper': return Icons.volunteer_activism;
      case 'neat_freak': return Icons.cleaning_services;
      case 'cleaning_champion': return Icons.cleaning_services_outlined;
      case 'early_bird': return Icons.wb_sunny;
      case 'night_owl': return Icons.nightlight_round;
      case 'overachiever': return Icons.emoji_events;
      case 'family_hero': return Icons.military_tech;
      default: return Icons.star;
    }
  }
}

/// Widget to display a badge grid with a provider for the gamification service
class BadgesProviderWidget extends StatelessWidget {
  final UserProfile userProfile;
  final bool showUnlockAnimation;
  final app_badge.Badge? newlyUnlockedBadge;

  const BadgesProviderWidget({
    Key? key,
    required this.userProfile,
    this.showUnlockAnimation = false,
    this.newlyUnlockedBadge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationServiceInterface>(
      builder: (context, gamificationService, child) {
        return FutureBuilder<List<app_badge.Badge>>(
          future: gamificationService.getAllBadges(),
          builder: (context, allBadgesSnapshot) {
            if (!allBadgesSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return FutureBuilder<List<app_badge.Badge>>(
              future: gamificationService.getUserBadges(userProfile.id),
              builder: (context, userBadgesSnapshot) {
                if (!userBadgesSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return BadgesWidget(
                  userProfile: userProfile,
                  allBadges: allBadgesSnapshot.data!,
                  unlockedBadges: userBadgesSnapshot.data!,
                  showUnlockAnimation: showUnlockAnimation,
                  newlyUnlockedBadge: newlyUnlockedBadge,
                );
              },
            );
          },
        );
      },
    );
  }
}
