import 'package:flutter/material.dart' hide Badge; // Hide Flutter's Badge widget
import 'package:hoque_family_chores/models/badge.dart'; // Correctly import your Badge model
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/models/achievement.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/services/gamification_service_interface.dart';
import 'package:hoque_family_chores/services/data_service_interface.dart';
import 'package:hoque_family_chores/services/logging_service.dart';
import 'dart:async';

class GamificationProvider with ChangeNotifier {
  late GamificationServiceInterface _gamificationService;
  late DataServiceInterface _dataService;

  UserProfile? _userProfile;
  List<Badge> _unlockedBadges = const [];
  final List<Reward> _redeemedRewards = const []; // Marked as final
  List<Achievement> _userAchievements = const [];
  List<Badge> _predefinedBadges = const [];
  List<Reward> _predefinedRewards = const [];

  bool _isLoading = false;
  String? _errorMessage;

  // Getters for UI consumption
  UserProfile? get userProfile => _userProfile;
  List<Badge> get unlockedBadges => _unlockedBadges;
  List<Reward> get redeemedRewards => _redeemedRewards;
  List<Achievement> get userAchievements => _userAchievements;
  List<Badge> get predefinedBadges => _predefinedBadges;
  List<Reward> get predefinedRewards => _predefinedRewards;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Stream subscriptions to manage data updates
  StreamSubscription? _userProfileSubscription;
  StreamSubscription? _unlockedBadgesSubscription;
  StreamSubscription? _userAchievementsSubscription;

  GamificationProvider();

  // No @override needed for updateDependencies unless it implements an interface with this method
  void updateDependencies({
    required GamificationServiceInterface gamificationService,
    required DataServiceInterface dataService,
  }) {
    if (!identical(_gamificationService, gamificationService) || !identical(_dataService, dataService)) {
      _gamificationService = gamificationService;
      _dataService = dataService;
      logger.d("GamificationProvider: Dependencies updated.");
    }
  }

  // Method required by GamificationScreen
  Future<void> loadAllData(String userId) async {
    if (_isLoading) return;

    logger.i("GamificationProvider: Loading all gamification data for user: $userId");
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _predefinedBadges = await _gamificationService.getPredefinedBadges();
      _predefinedRewards = await _gamificationService.getPredefinedRewards();
      logger.d("GamificationProvider: Predefined badges (${_predefinedBadges.length}) and rewards (${_predefinedRewards.length}) loaded.");

      _userProfileSubscription?.cancel();
      _userProfileSubscription = _dataService.streamUserProfile(userId: userId).listen(
        (profile) {
          _userProfile = profile;
          notifyListeners();
          logger.d("GamificationProvider: UserProfile updated.");
        },
        onError: (e, s) {
          _errorMessage = "Failed to stream user profile: $e";
          logger.e("Error streaming user profile: $e", error: e, stackTrace: s);
        },
      );

      _unlockedBadgesSubscription?.cancel();
      _unlockedBadgesSubscription = _dataService.streamUserBadges(userId: userId).listen(
        (badges) {
          _unlockedBadges = badges;
          notifyListeners();
          logger.d("GamificationProvider: Unlocked badges updated (${badges.length}).");
        },
        onError: (e, s) {
          _errorMessage = "Failed to stream unlocked badges: $e";
          logger.e("Error streaming unlocked badges: $e", error: e, stackTrace: s);
        },
      );

      _userAchievementsSubscription?.cancel();
      _userAchievementsSubscription = _dataService.streamUserAchievements(userId: userId).listen(
        (achievements) {
          _userAchievements = achievements;
          notifyListeners();
          logger.d("GamificationProvider: User achievements updated (${achievements.length}).");
        },
        onError: (e, s) {
          _errorMessage = "Failed to stream user achievements: $e";
          logger.e("Error streaming user achievements: $e", error: e, stackTrace: s);
        },
      );
    } catch (e, s) {
      _errorMessage = "GamificationProvider: Error loading initial data: $e";
      logger.e("GamificationProvider: Error loading initial data: $e", error: e, stackTrace: s);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Actions ---

  Future<void> redeemReward(String rewardId) async {
    if (_userProfile == null || _userProfile!.id.isEmpty) {
      _errorMessage = "No user profile available to redeem reward.";
      notifyListeners();
      return;
    }
    logger.i("GamificationProvider: Attempting to redeem reward $rewardId for user ${_userProfile!.id}.");
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rewardToRedeem = _predefinedRewards.firstWhere((r) => r.id == rewardId);

      if (_userProfile!.totalPoints < rewardToRedeem.pointsCost) {
        _errorMessage = "Not enough points to redeem this reward.";
        logger.w(_errorMessage!);
        return;
      }

      await _dataService.updateUserPoints(
        userId: _userProfile!.id,
        points: -rewardToRedeem.pointsCost,
      );

      await _dataService.updateUserProfile(
        user: _userProfile!.copyWith(
          redeemedRewards: [..._userProfile!.redeemedRewards, rewardToRedeem.copyWith(
            isRedeemed: true,
            redeemedAt: DateTime.now(),
            redeemedBy: _userProfile!.id,
          )],
        ),
      );
      logger.i("Reward $rewardId redeemed successfully.");
    } catch (e, s) {
      _errorMessage = "Failed to redeem reward: $e";
      logger.e("Error redeeming reward $rewardId: $e", error: e, stackTrace: s);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override // Keep @override for dispose
  void dispose() {
    _userProfileSubscription?.cancel();
    _unlockedBadgesSubscription?.cancel();
    _userAchievementsSubscription?.cancel();
    logger.i("GamificationProvider disposed.");
    super.dispose();
  }
}