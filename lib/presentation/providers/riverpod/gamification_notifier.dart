import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/domain/entities/achievement.dart';
import 'package:hoque_family_chores/domain/entities/badge.dart' show Badge, BadgeType;
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/usecases/gamification/award_points_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/gamification/redeem_reward_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/gamification/award_badge_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/gamification/grant_achievement_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/gamification/get_badges_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/gamification/get_rewards_usecase.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';

part 'gamification_notifier.g.dart';

/// Manages gamification data including badges, rewards, achievements, and points.
/// 
/// This notifier handles all gamification-related operations including
/// awarding points, badges, achievements, and redeeming rewards.
/// 
/// Example:
/// ```dart
/// final gamificationAsync = ref.watch(gamificationNotifierProvider(userId));
/// final notifier = ref.read(gamificationNotifierProvider(userId).notifier);
/// await notifier.awardPoints(points, reason);
/// ```
@riverpod
class GamificationNotifier extends _$GamificationNotifier {
  final _logger = AppLogger();

  @override
  Future<GamificationData> build(UserId userId) async {
    _logger.d('GamificationNotifier: Building for user $userId');
    
    try {
      // Load user profile first to get familyId
      final userProfile = await _loadUserProfile(userId);
      final userFamilyId = userProfile?.familyId ?? FamilyId('default');
      
      // Load all gamification data in parallel
      final futures = await Future.wait([
        Future.value(userProfile),
        _loadBadges(userFamilyId),
        _loadRewards(userFamilyId),
        _loadUserAchievements(userId),
        _loadUserBadges(userId),
        _loadRedeemedRewards(userId),
      ]);
      
      return GamificationData(
        userProfile: futures[0] as User?,
        allBadges: futures[1] as List<Badge>,
        allRewards: futures[2] as List<Reward>,
        userAchievements: futures[3] as List<Achievement>,
        userBadges: futures[4] as List<Badge>,
        redeemedRewards: futures[5] as List<Reward>,
      );
    } catch (e) {
      _logger.e('GamificationNotifier: Error loading gamification data', error: e);
      throw Exception('Failed to load gamification data: $e');
    }
  }

  /// Loads user profile data.
  Future<User?> _loadUserProfile(UserId userId) async {
    try {
      // This would use a user repository or service
      // For now, return null as placeholder
      return null;
    } catch (e) {
      _logger.e('GamificationNotifier: Error loading user profile', error: e);
      return null;
    }
  }

  /// Loads badges for the family.
  Future<List<Badge>> _loadBadges(FamilyId familyId) async {
    _logger.d('GamificationNotifier: Loading badges for family $familyId');
    
    try {
      final getBadgesUseCase = ref.watch(getBadgesUseCaseProvider);
      final result = await getBadgesUseCase.call(familyId: familyId);
      
      return result.fold(
        (failure) => throw Exception(failure.message),
        (badges) {
          _logger.d('GamificationNotifier: Loaded ${badges.length} badges');
          return badges;
        },
      );
    } catch (e) {
      _logger.e('GamificationNotifier: Error loading badges', error: e);
      throw Exception('Failed to load badges: $e');
    }
  }

  /// Loads rewards for the family.
  Future<List<Reward>> _loadRewards(FamilyId familyId) async {
    _logger.d('GamificationNotifier: Loading rewards for family $familyId');
    
    try {
      final getRewardsUseCase = ref.watch(getRewardsUseCaseProvider);
      final result = await getRewardsUseCase.call(familyId: familyId);
      
      return result.fold(
        (failure) => throw Exception(failure.message),
        (rewards) {
          _logger.d('GamificationNotifier: Loaded ${rewards.length} rewards');
          return rewards;
        },
      );
    } catch (e) {
      _logger.e('GamificationNotifier: Error loading rewards', error: e);
      throw Exception('Failed to load rewards: $e');
    }
  }

  /// Loads user achievements.
  Future<List<Achievement>> _loadUserAchievements(UserId userId) async {
    try {
      // This would use an achievement repository or service
      // For now, return empty list as placeholder
      return [];
    } catch (e) {
      _logger.e('GamificationNotifier: Error loading user achievements', error: e);
      return [];
    }
  }

  /// Loads user badges.
  Future<List<Badge>> _loadUserBadges(UserId userId) async {
    try {
      // This would use a badge repository or service
      // For now, return empty list as placeholder
      return [];
    } catch (e) {
      _logger.e('GamificationNotifier: Error loading user badges', error: e);
      return [];
    }
  }

  /// Loads redeemed rewards.
  Future<List<Reward>> _loadRedeemedRewards(UserId userId) async {
    try {
      // This would use a reward repository or service
      // For now, return empty list as placeholder
      return [];
    } catch (e) {
      _logger.e('GamificationNotifier: Error loading redeemed rewards', error: e);
      return [];
    }
  }

  /// Awards points to a user.
  Future<void> awardPoints(UserId userId, int points) async {
    _logger.d('GamificationNotifier: Awarding $points points to user $userId');
    
    try {
      final awardPointsUseCase = ref.read(awardPointsUseCaseProvider);
      final result = await awardPointsUseCase.call(
        userId: userId,
        points: points,
      );
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('GamificationNotifier: Points awarded successfully');
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('GamificationNotifier: Error awarding points', error: e);
      throw Exception('Failed to award points: $e');
    }
  }

  /// Awards a badge to a user.
  Future<void> awardBadge(UserId userId, String badgeId, FamilyId familyId) async {
    _logger.d('GamificationNotifier: Awarding badge $badgeId to user $userId');
    
    try {
      final awardBadgeUseCase = ref.read(awardBadgeUseCaseProvider);
      final result = await awardBadgeUseCase.call(
        userId: userId,
        badgeId: badgeId,
        familyId: familyId,
      );
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('GamificationNotifier: Badge awarded successfully');
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('GamificationNotifier: Error awarding badge', error: e);
      throw Exception('Failed to award badge: $e');
    }
  }

  /// Grants an achievement to a user.
  Future<void> grantAchievement(UserId userId, String achievementId, FamilyId familyId) async {
    _logger.d('GamificationNotifier: Granting achievement $achievementId to user $userId');
    
    try {
      final grantAchievementUseCase = ref.read(grantAchievementUseCaseProvider);
      // TODO: This should accept an Achievement entity; for now, create a minimal one
      final achievement = Achievement(
        id: achievementId,
        title: 'Achievement $achievementId',
        description: '',
        points: Points(0),
        icon: '',
        type: BadgeType.special,
        createdAt: DateTime.now(),
      );
      final result = await grantAchievementUseCase.call(
        userId: userId,
        achievement: achievement,
      );
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('GamificationNotifier: Achievement granted successfully');
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('GamificationNotifier: Error granting achievement', error: e);
      throw Exception('Failed to grant achievement: $e');
    }
  }

  /// Redeems a reward for a user.
  Future<void> redeemReward(UserId userId, String rewardId, FamilyId familyId) async {
    _logger.d('GamificationNotifier: Redeeming reward $rewardId for user $userId');
    
    try {
      final redeemRewardUseCase = ref.read(redeemRewardUseCaseProvider);
      final result = await redeemRewardUseCase.call(
        userId: userId,
        rewardId: rewardId,
        familyId: familyId,
      );
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('GamificationNotifier: Reward redeemed successfully');
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('GamificationNotifier: Error redeeming reward', error: e);
      throw Exception('Failed to redeem reward: $e');
    }
  }

  /// Refreshes the gamification data.
  Future<void> refresh() async {
    _logger.d('GamificationNotifier: Refreshing gamification data');
    ref.invalidateSelf();
  }

  /// Gets the current gamification data.
  GamificationData? get data => state.value;

  /// Gets the current loading state.
  bool get isLoading => state.isLoading;

  /// Gets the current error message.
  String? get errorMessage => state.hasError ? state.error.toString() : null;

  /// Gets the user profile.
  User? get userProfile => data?.userProfile;

  /// Gets all available badges.
  List<Badge> get allBadges => data?.allBadges ?? [];

  /// Gets all available rewards.
  List<Reward> get allRewards => data?.allRewards ?? [];

  /// Gets user achievements.
  List<Achievement> get userAchievements => data?.userAchievements ?? [];

  /// Gets user badges.
  List<Badge> get userBadges => data?.userBadges ?? [];

  /// Gets redeemed rewards.
  List<Reward> get redeemedRewards => data?.redeemedRewards ?? [];

  /// Gets available rewards (not yet redeemed).
  List<Reward> get availableRewards {
    final redeemedIds = redeemedRewards.map((r) => r.id).toSet();
    return allRewards.where((reward) => !redeemedIds.contains(reward.id)).toList();
  }

  /// Gets unlocked badges.
  List<Badge> get unlockedBadges => userBadges;

  /// Gets locked badges.
  List<Badge> get lockedBadges {
    final unlockedIds = userBadges.map((b) => b.id).toSet();
    return allBadges.where((badge) => !unlockedIds.contains(badge.id)).toList();
  }

  /// Gets total points earned.
  int get totalPointsEarned {
    return userProfile?.points?.value ?? 0;
  }

  /// Gets total achievements earned.
  int get totalAchievements => userAchievements.length;

  /// Gets total badges unlocked.
  int get totalBadgesUnlocked => userBadges.length;

  /// Gets total rewards redeemed.
  int get totalRewardsRedeemed => redeemedRewards.length;
}

/// Data class for gamification information.
class GamificationData {
  final User? userProfile;
  final List<Badge> allBadges;
  final List<Reward> allRewards;
  final List<Achievement> userAchievements;
  final List<Badge> userBadges;
  final List<Reward> redeemedRewards;

  const GamificationData({
    this.userProfile,
    required this.allBadges,
    required this.allRewards,
    required this.userAchievements,
    required this.userBadges,
    required this.redeemedRewards,
  });
} 