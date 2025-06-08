// lib/presentation/providers/gamification_provider.dart
import 'package:flutter/material.dart' as material;
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/services/gamification_service.dart';

enum GamificationLoadingState {
  initial,
  loading,
  loaded,
  error,
}

class GamificationProvider extends material.ChangeNotifier {
  final GamificationServiceInterface _gamificationService;
  
  UserProfile? _userProfile;
  GamificationLoadingState _profileState = GamificationLoadingState.initial;
  String? _profileError;

  List<Badge> _allBadges = [];
  List<Badge> _userBadges = [];
  GamificationLoadingState _badgesState = GamificationLoadingState.initial;
  String? _badgesError;
  Badge? _newlyUnlockedBadge;

  List<Reward> _allRewards = [];
  List<Reward> _userRewards = [];
  GamificationLoadingState _rewardsState = GamificationLoadingState.initial;
  String? _rewardsError;
  Reward? _newlyPurchasedReward;

  final List<GamificationEvent> _recentEvents = [];
  
  bool _showLevelUpAnimation = false;
  bool _showBadgeUnlockAnimation = false;
  bool _showRewardPurchaseAnimation = false;

  GamificationProvider(this._gamificationService);

  // Getters
  UserProfile? get userProfile => _userProfile;
  GamificationLoadingState get profileState => _profileState;
  String? get profileError => _profileError;

  List<Badge> get allBadges => _allBadges;
  List<Badge> get userBadges => _userBadges;
  GamificationLoadingState get badgesState => _badgesState;
  String? get badgesError => _badgesError;
  Badge? get newlyUnlockedBadge => _newlyUnlockedBadge;

  List<Reward> get allRewards => _allRewards;
  List<Reward> get userRewards => _userRewards;
  GamificationLoadingState get rewardsState => _rewardsState;
  String? get rewardsError => _rewardsError;
  Reward? get newlyPurchasedReward => _newlyPurchasedReward;

  List<GamificationEvent> get recentEvents => List.unmodifiable(_recentEvents);

  bool get showLevelUpAnimation => _showLevelUpAnimation;
  bool get showBadgeUnlockAnimation => _showBadgeUnlockAnimation;
  bool get showRewardPurchaseAnimation => _showRewardPurchaseAnimation;

  // Load all gamification data
  Future<void> loadAllData(String userId) async {
    await Future.wait([
      _loadUserProfile(userId),
      _loadBadges(userId),
      _loadRewards(userId),
    ]);
  }

  // User Profile Methods
  Future<void> _loadUserProfile(String userId) async {
    _profileState = GamificationLoadingState.loading;
    notifyListeners();

    try {
      final profile = await _gamificationService.getUserProfile(userId);
      _userProfile = profile;
      _profileState = GamificationLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _profileState = GamificationLoadingState.error;
      _profileError = e.toString();
      notifyListeners();
    }
  }

  Future<void> retryLoadProfile(String userId) async {
    await _loadUserProfile(userId);
  }

  // Badge Methods
  Future<void> _loadBadges(String userId) async {
    _badgesState = GamificationLoadingState.loading;
    notifyListeners();

    try {
      final allBadges = await _gamificationService.getAllBadges();
      final userBadges = await _gamificationService.getUserBadges(userId);
      
      _allBadges = allBadges;
      _userBadges = userBadges;
      _badgesState = GamificationLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _badgesState = GamificationLoadingState.error;
      _badgesError = e.toString();
      notifyListeners();
    }
  }

  Future<void> retryLoadBadges(String userId) async {
    await _loadBadges(userId);
  }

  // Reward Methods
  Future<void> _loadRewards(String userId) async {
    _rewardsState = GamificationLoadingState.loading;
    notifyListeners();

    try {
      final allRewards = await _gamificationService.getAllRewards();
      final userRewards = await _gamificationService.getUserRedeemedRewards(userId);
      
      _allRewards = allRewards;
      _userRewards = userRewards;
      _rewardsState = GamificationLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _rewardsState = GamificationLoadingState.error;
      _rewardsError = e.toString();
      notifyListeners();
    }
  }

  Future<void> retryLoadRewards(String userId) async {
    await _loadRewards(userId);
  }

  // Redeem a reward
  Future<bool> redeemReward(String userId, String rewardId) async {
    if (_userProfile == null) return false;
    
    try {
      final reward = _allRewards.firstWhere((r) => r.id == rewardId);
      
      // Check if user has enough points
      if (_userProfile!.totalPoints < reward.pointsCost) {
        return false;
      }
      
      // Redeem the reward
      final success = await _gamificationService.redeemReward(userId, rewardId);
      
      if (success) {
        // Update user profile with new points
        _userProfile = _userProfile!.copyWith(
          totalPoints: _userProfile!.totalPoints - reward.pointsCost,
        );
        
        // Add reward to user rewards
        final redeemedReward = reward.copyWith(
          redeemedAt: DateTime.now(),
        );
        _userRewards.add(redeemedReward);
        
        // Add event
        _addEvent(
          GamificationEventType.rewardRedeemed,
          'Redeemed "${reward.title}" for ${reward.pointsCost} points',
          {'rewardId': rewardId},
        );
        
        // Show animation
        _newlyPurchasedReward = redeemedReward;
        _showRewardPurchaseAnimation = true;
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Add a gamification event
  void _addEvent(
    GamificationEventType type,
    String message,
    Map<String, dynamic>? data,
  ) {
    final event = GamificationEvent(
      type: type,
      userId: _userProfile?.id ?? '',
      message: message,
      data: data,
    );
    
    _recentEvents.insert(0, event);
    
    // Keep only the most recent 20 events
    if (_recentEvents.length > 20) {
      _recentEvents.removeLast();
    }
    
    notifyListeners();
  }

  // Reset animations
  void resetAnimations() {
    _showLevelUpAnimation = false;
    _showBadgeUnlockAnimation = false;
    _showRewardPurchaseAnimation = false;
    _newlyUnlockedBadge = null;
    _newlyPurchasedReward = null;
    notifyListeners();
  }
}
