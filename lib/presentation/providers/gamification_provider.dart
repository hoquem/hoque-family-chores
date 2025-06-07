// lib/presentation/providers/gamification_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/services/gamification_service.dart';

/// Enum representing the loading state of gamification data
enum GamificationLoadingState {
  initial,
  loading,
  loaded,
  error,
}

/// Provider for managing gamification state in the app
class GamificationProvider extends ChangeNotifier {
  final GamificationServiceInterface _gamificationService;
  
  // User profile data
  UserProfile? _userProfile;
  GamificationLoadingState _profileState = GamificationLoadingState.initial;
  String? _profileError;
  
  // Badges data
  List<Badge> _allBadges = [];
  List<Badge> _userBadges = [];
  GamificationLoadingState _badgesState = GamificationLoadingState.initial;
  String? _badgesError;
  
  // Rewards data
  List<Reward> _allRewards = [];
  List<Reward> _userRewards = [];
  GamificationLoadingState _rewardsState = GamificationLoadingState.initial;
  String? _rewardsError;
  
  // Animation states
  bool _showLevelUpAnimation = false;
  bool _showBadgeUnlockAnimation = false;
  bool _showRewardPurchaseAnimation = false;
  Badge? _newlyUnlockedBadge;
  Reward? _newlyPurchasedReward;
  
  // Event handling
  StreamSubscription<GamificationEvent>? _eventSubscription;
  List<GamificationEvent> _recentEvents = [];
  
  // Constructor
  GamificationProvider(this._gamificationService) {
    // Listen to gamification events
    _eventSubscription = _gamificationService.events.listen(_handleGamificationEvent);
  }
  
  // Getters for user profile
  UserProfile? get userProfile => _userProfile;
  GamificationLoadingState get profileState => _profileState;
  String? get profileError => _profileError;
  
  // Getters for badges
  List<Badge> get allBadges => _allBadges;
  List<Badge> get userBadges => _userBadges;
  GamificationLoadingState get badgesState => _badgesState;
  String? get badgesError => _badgesError;
  
  // Getters for rewards
  List<Reward> get allRewards => _allRewards;
  List<Reward> get userRewards => _userRewards;
  GamificationLoadingState get rewardsState => _rewardsState;
  String? get rewardsError => _rewardsError;
  
  // Getters for animation states
  bool get showLevelUpAnimation => _showLevelUpAnimation;
  bool get showBadgeUnlockAnimation => _showBadgeUnlockAnimation;
  bool get showRewardPurchaseAnimation => _showRewardPurchaseAnimation;
  Badge? get newlyUnlockedBadge => _newlyUnlockedBadge;
  Reward? get newlyPurchasedReward => _newlyPurchasedReward;
  
  // Getters for events
  List<GamificationEvent> get recentEvents => _recentEvents;
  
  /// Load user profile data
  Future<void> loadUserProfile(String userId) async {
    if (_profileState == GamificationLoadingState.loading) return;
    
    _profileState = GamificationLoadingState.loading;
    _profileError = null;
    notifyListeners();
    
    try {
      final profile = await _gamificationService.getUserProfile(userId);
      _userProfile = profile;
      _profileState = GamificationLoadingState.loaded;
    } catch (e) {
      _profileError = e.toString();
      _profileState = GamificationLoadingState.error;
      debugPrint('Error loading user profile: $e');
    }
    
    notifyListeners();
  }
  
  /// Load badges data
  Future<void> loadBadges(String userId) async {
    if (_badgesState == GamificationLoadingState.loading) return;
    
    _badgesState = GamificationLoadingState.loading;
    _badgesError = null;
    notifyListeners();
    
    try {
      final allBadges = await _gamificationService.getAllBadges();
      final userBadges = await _gamificationService.getUserBadges(userId);
      
      _allBadges = allBadges;
      _userBadges = userBadges;
      _badgesState = GamificationLoadingState.loaded;
    } catch (e) {
      _badgesError = e.toString();
      _badgesState = GamificationLoadingState.error;
      debugPrint('Error loading badges: $e');
    }
    
    notifyListeners();
  }
  
  /// Load rewards data
  Future<void> loadRewards(String userId) async {
    if (_rewardsState == GamificationLoadingState.loading) return;
    
    _rewardsState = GamificationLoadingState.loading;
    _rewardsError = null;
    notifyListeners();
    
    try {
      final allRewards = await _gamificationService.getAllRewards();
      final userRewards = await _gamificationService.getUserRedeemedRewards(userId);
      
      _allRewards = allRewards;
      _userRewards = userRewards;
      _rewardsState = GamificationLoadingState.loaded;
    } catch (e) {
      _rewardsError = e.toString();
      _rewardsState = GamificationLoadingState.error;
      debugPrint('Error loading rewards: $e');
    }
    
    notifyListeners();
  }
  
  /// Load all gamification data for a user
  Future<void> loadAllData(String userId) async {
    await Future.wait([
      loadUserProfile(userId),
      loadBadges(userId),
      loadRewards(userId),
    ]);
  }
  
  /// Handle task completion
  Future<void> completeTask(String userId, Task task) async {
    try {
      final oldLevel = _userProfile?.currentLevel ?? 0;
      
      // Update user profile with completed task
      final updatedProfile = await _gamificationService.handleTaskCompletion(userId, task);
      _userProfile = updatedProfile;
      
      // Check if user leveled up
      if (updatedProfile.currentLevel > oldLevel) {
        _showLevelUpAnimation = true;
        notifyListeners();
        
        // Reset animation flag after delay
        Future.delayed(const Duration(seconds: 3), () {
          _showLevelUpAnimation = false;
          notifyListeners();
        });
      }
      
      // Refresh badges after task completion
      await loadBadges(userId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing task: $e');
      // Show error to user
      rethrow;
    }
  }
  
  /// Check for and unlock badges
  Future<void> checkAndUnlockBadges(String userId) async {
    try {
      final newBadges = await _gamificationService.checkAndUnlockBadges(userId);
      
      if (newBadges.isNotEmpty) {
        // Update user badges
        await loadBadges(userId);
        
        // Show badge unlock animation for the first new badge
        _newlyUnlockedBadge = newBadges.first;
        _showBadgeUnlockAnimation = true;
        notifyListeners();
        
        // Reset animation flag after delay
        Future.delayed(const Duration(seconds: 3), () {
          _showBadgeUnlockAnimation = false;
          notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('Error checking for badges: $e');
      // Handle error silently to not disrupt user flow
    }
  }
  
  /// Redeem a reward
  Future<bool> redeemReward(String userId, String rewardId) async {
    try {
      // Find the reward
      final reward = _allRewards.firstWhere((r) => r.id == rewardId);
      
      // Check if user can afford it
      final canAfford = await _gamificationService.canRedeemReward(userId, reward);
      if (!canAfford) {
        return false;
      }
      
      // Redeem the reward
      final success = await _gamificationService.redeemReward(userId, rewardId);
      
      if (success) {
        // Refresh user profile and rewards
        await loadUserProfile(userId);
        await loadRewards(userId);
        
        // Show reward purchase animation
        _newlyPurchasedReward = reward;
        _showRewardPurchaseAnimation = true;
        notifyListeners();
        
        // Reset animation flag after delay
        Future.delayed(const Duration(seconds: 3), () {
          _showRewardPurchaseAnimation = false;
          notifyListeners();
        });
      }
      
      return success;
    } catch (e) {
      debugPrint('Error redeeming reward: $e');
      return false;
    }
  }
  
  /// Award points to a user
  Future<void> awardPoints(String userId, int points, String reason) async {
    try {
      final oldLevel = _userProfile?.currentLevel ?? 0;
      
      // Award points
      final updatedProfile = await _gamificationService.awardPoints(userId, points, reason);
      _userProfile = updatedProfile;
      
      // Check if user leveled up
      if (updatedProfile.currentLevel > oldLevel) {
        _showLevelUpAnimation = true;
        notifyListeners();
        
        // Reset animation flag after delay
        Future.delayed(const Duration(seconds: 3), () {
          _showLevelUpAnimation = false;
          notifyListeners();
        });
      }
      
      // Check for new badges
      await checkAndUnlockBadges(userId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error awarding points: $e');
      rethrow;
    }
  }
  
  /// Get level progress for a user
  Future<Map<String, dynamic>> getLevelProgress(String userId) async {
    try {
      return await _gamificationService.getLevelProgress(userId);
    } catch (e) {
      debugPrint('Error getting level progress: $e');
      return {
        'currentLevel': _userProfile?.currentLevel ?? 0,
        'totalPoints': _userProfile?.totalPoints ?? 0,
        'pointsToNextLevel': _userProfile?.pointsToNextLevel ?? 100,
        'progressPercentage': _userProfile?.levelProgressPercentage ?? 0,
      };
    }
  }
  
  /// Handle gamification events from service
  void _handleGamificationEvent(GamificationEvent event) {
    // Add to recent events list (keep last 10)
    _recentEvents.insert(0, event);
    if (_recentEvents.length > 10) {
      _recentEvents.removeLast();
    }
    
    // Handle different event types
    switch (event.type) {
      case GamificationEventType.levelUp:
        // Level up animation will be handled by awardPoints method
        break;
      
      case GamificationEventType.badgeUnlocked:
        if (event.data is Badge) {
          _newlyUnlockedBadge = event.data as Badge;
          _showBadgeUnlockAnimation = true;
          
          // Reset animation flag after delay
          Future.delayed(const Duration(seconds: 3), () {
            _showBadgeUnlockAnimation = false;
            notifyListeners();
          });
        }
        break;
      
      case GamificationEventType.rewardRedeemed:
        if (event.data is Reward) {
          _newlyPurchasedReward = event.data as Reward;
          _showRewardPurchaseAnimation = true;
          
          // Reset animation flag after delay
          Future.delayed(const Duration(seconds: 3), () {
            _showRewardPurchaseAnimation = false;
            notifyListeners();
          });
        }
        break;
      
      default:
        // For other events, just refresh data if needed
        break;
    }
    
    // Notify listeners of the new event
    notifyListeners();
  }
  
  /// Reset animation states
  void resetAnimations() {
    _showLevelUpAnimation = false;
    _showBadgeUnlockAnimation = false;
    _showRewardPurchaseAnimation = false;
    notifyListeners();
  }
  
  /// Retry loading user profile
  Future<void> retryLoadProfile(String userId) async {
    await loadUserProfile(userId);
  }
  
  /// Retry loading badges
  Future<void> retryLoadBadges(String userId) async {
    await loadBadges(userId);
  }
  
  /// Retry loading rewards
  Future<void> retryLoadRewards(String userId) async {
    await loadRewards(userId);
  }
  
  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}
