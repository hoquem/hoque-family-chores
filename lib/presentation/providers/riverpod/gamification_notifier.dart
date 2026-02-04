import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/domain/entities/achievement.dart';
import 'package:hoque_family_chores/domain/entities/badge.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
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
/// await notifier.awardPoints(10, familyId);
/// ```
@riverpod
class GamificationNotifier extends _$GamificationNotifier {
  final _logger = AppLogger();

  @override
  Future<GamificationData> build(UserId userId) async {
    _logger.d('GamificationNotifier: Building for user $userId');
    
    try {
      // Load all gamification data
      return GamificationData(
        userProfile: null,
        allBadges: [],
        allRewards: [],
        userAchievements: [],
        userBadges: [],
        redeemedRewards: [],
      );
    } catch (e) {
      _logger.e('GamificationNotifier: Error loading gamification data', error: e);
      throw Exception('Failed to load gamification data: $e');
    }
  }

  /// Loads badges for the family.
  Future<List<Badge>> loadBadges(FamilyId familyId) async {
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
  Future<List<Reward>> loadRewards(FamilyId familyId) async {
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

  /// Awards points to the user.
  Future<void> awardPoints(int points, FamilyId familyId) async {
    _logger.d('GamificationNotifier: Awarding $points points');
    
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

  /// Awards a badge to the user.
  Future<void> awardBadge(String badgeId, FamilyId familyId) async {
    _logger.d('GamificationNotifier: Awarding badge $badgeId');
    
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

  /// Grants an achievement to the user.
  Future<void> grantAchievement(Achievement achievement, FamilyId familyId) async {
    _logger.d('GamificationNotifier: Granting achievement ${achievement.id}');
    
    try {
      final grantAchievementUseCase = ref.read(grantAchievementUseCaseProvider);
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

  /// Redeems a reward for the user.
  Future<void> redeemReward(String rewardId, FamilyId familyId) async {
    _logger.d('GamificationNotifier: Redeeming reward $rewardId');
    
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

  /// Gets total points earned.
  int get totalPointsEarned => userProfile?.points.value ?? 0;

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
