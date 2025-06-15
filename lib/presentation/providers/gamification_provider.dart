import 'package:flutter/material.dart'
    hide Badge; // Hide Flutter's Badge widget
import 'package:hoque_family_chores/models/badge.dart'; // Correctly import your Badge model
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/models/achievement.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/services/interfaces/gamification_service_interface.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'dart:async';

class GamificationProvider with ChangeNotifier {
  final GamificationServiceInterface _gamificationService;
  final _logger = AppLogger();

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

  GamificationProvider({
    required GamificationServiceInterface gamificationService,
  }) : _gamificationService = gamificationService {
    _logger.d("GamificationProvider initialized with dependencies.");
  }

  void updateDependencies({
    required GamificationServiceInterface gamificationService,
  }) {
    if (!identical(_gamificationService, gamificationService)) {
      _logger.d("GamificationProvider: Dependencies updated.");
    }
  }

  // New method to initialize gamification data after login
  Future<void> initializeAfterLogin(String userId) async {
    if (userId.isEmpty) {
      _logger.w("GamificationProvider: Cannot initialize - empty user ID");
      return;
    }

    _logger.i(
      "GamificationProvider: Initializing after login for user: $userId",
    );

    try {
      // Get the user's family ID from their profile
      final userProfile = await _gamificationService.getUserProfile(
        userId: userId,
      );
      if (userProfile == null || userProfile.member.familyId.isEmpty) {
        _logger.w(
          "GamificationProvider: Cannot initialize - no family ID found",
        );
        return;
      }

      // Initialize user data through the service
      await _gamificationService.initializeUserData(
        userId: userId,
        familyId: userProfile.member.familyId,
      );

      // Load all data after initialization
      await loadAllData(userId);
    } catch (e, s) {
      _errorMessage = "Failed to initialize gamification data: $e";
      _logger.e(
        "GamificationProvider: Error initializing after login: $e",
        error: e,
        stackTrace: s,
      );
    }
  }

  // Method required by GamificationScreen
  Future<void> loadAllData(String userId) async {
    if (_isLoading) return;

    _logger.i(
      "GamificationProvider: Loading all gamification data for user: $userId",
    );
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _predefinedBadges = await _gamificationService.getBadges(
        familyId: userId,
      );
      _predefinedRewards = await _gamificationService.getRewards(
        familyId: userId,
      );
      _logger.d(
        "GamificationProvider: Predefined badges (${_predefinedBadges.length}) and rewards (${_predefinedRewards.length}) loaded.",
      );

      _userProfileSubscription?.cancel();
      _userProfileSubscription = _gamificationService
          .streamUserProfile(userId: userId)
          .listen(
            (profile) {
              _userProfile = profile;
              notifyListeners();
              _logger.d("GamificationProvider: UserProfile updated.");
            },
            onError: (e, s) {
              _errorMessage = "Failed to stream user profile: $e";
              _logger.e(
                "Error streaming user profile: $e",
                error: e,
                stackTrace: s,
              );
            },
          );

      _unlockedBadgesSubscription?.cancel();
      _unlockedBadgesSubscription = _gamificationService
          .streamUserBadges(userId: userId)
          .listen(
            (badges) {
              _unlockedBadges = badges;
              notifyListeners();
              _logger.d(
                "GamificationProvider: Unlocked badges updated (${badges.length}).",
              );
            },
            onError: (e, s) {
              _errorMessage = "Failed to stream unlocked badges: $e";
              _logger.e(
                "Error streaming unlocked badges: $e",
                error: e,
                stackTrace: s,
              );
            },
          );

      _userAchievementsSubscription?.cancel();
      _userAchievementsSubscription = _gamificationService
          .streamUserAchievements(userId: userId)
          .listen(
            (achievements) async {
              _userAchievements = achievements;
              notifyListeners();
              _logger.d(
                "GamificationProvider: User achievements updated (${achievements.length}).",
              );

              // If no achievements exist, create a default one
              if (achievements.isEmpty) {
                _logger.d(
                  'No achievements found, creating a default achievement...',
                );
                final now = DateTime.now();
                final defaultAchievement = Achievement(
                  id: '', // Firestore will assign an ID
                  title: 'Welcome Achievement',
                  description:
                      'This is your first achievement! Edit or delete as needed.',
                  points: 10,
                  icon: '🎉',
                  type: BadgeType.taskCompletion,
                  createdAt: now,
                  completedAt: null,
                  completedBy: null,
                );
                await _gamificationService.grantAchievement(
                  userId: userId,
                  achievement: defaultAchievement,
                );
                // No need to update _userAchievements here, will be updated on next stream event
              }
            },
            onError: (e, s) {
              _errorMessage = "Failed to stream user achievements: $e";
              _logger.e(
                "Error streaming user achievements: $e",
                error: e,
                stackTrace: s,
              );
            },
          );
    } catch (e, s) {
      _errorMessage = "GamificationProvider: Error loading initial data: $e";
      _logger.e(
        "GamificationProvider: Error loading initial data: $e",
        error: e,
        stackTrace: s,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Actions ---

  Future<void> redeemReward(String rewardId) async {
    if (_userProfile == null || _userProfile!.member.id.isEmpty) {
      _errorMessage = "No user profile available to redeem reward.";
      notifyListeners();
      return;
    }
    _logger.i(
      "GamificationProvider: Attempting to redeem reward $rewardId for user ${_userProfile!.member.id}.",
    );
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rewardToRedeem = _predefinedRewards.firstWhere(
        (r) => r.id == rewardId,
        orElse: () => throw Exception('Reward not found'),
      );

      await _gamificationService.redeemReward(
        familyId: _userProfile!.member.familyId,
        userId: _userProfile!.member.id,
        rewardId: rewardId,
      );

      _logger.i(
        "GamificationProvider: Successfully redeemed reward $rewardId for user ${_userProfile!.member.id}.",
      );
      _redeemedRewards.add(rewardToRedeem);
      notifyListeners();
    } catch (e, s) {
      _errorMessage = "Failed to redeem reward: $e";
      _logger.e(
        "GamificationProvider: Error redeeming reward: $e",
        error: e,
        stackTrace: s,
      );
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
    _logger.i("GamificationProvider disposed.");
    super.dispose();
  }
}
