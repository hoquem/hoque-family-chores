import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';

part 'reward_notifier.g.dart';

/// Manages reward-related state and operations.
/// 
/// This notifier handles loading rewards for a family and provides
/// methods for reward-related operations.
/// 
/// Example:
/// ```dart
/// final rewardsAsync = ref.watch(rewardNotifierProvider(familyId));
/// final notifier = ref.read(rewardNotifierProvider(familyId).notifier);
/// await notifier.refresh();
/// ```
@riverpod
class RewardNotifier extends _$RewardNotifier {
  final _logger = AppLogger();

  @override
  Future<List<Reward>> build(FamilyId familyId) async {
    _logger.d('RewardNotifier: Building for family $familyId');
    
    try {
      final getRewardsUseCase = ref.watch(getRewardsUseCaseProvider);
      final result = await getRewardsUseCase.call(familyId: familyId);
      
      return result.fold(
        (failure) => throw Exception(failure.message),
        (rewards) {
          _logger.d('RewardNotifier: Loaded ${rewards.length} rewards');
          return rewards;
        },
      );
    } catch (e) {
      _logger.e('RewardNotifier: Error loading rewards', error: e);
      throw Exception('Failed to load rewards: $e');
    }
  }

  /// Refreshes the rewards list.
  Future<void> refresh() async {
    _logger.d('RewardNotifier: Refreshing rewards');
    ref.invalidateSelf();
  }

  /// Gets the current list of rewards.
  List<Reward> get rewards => state.value ?? [];

  /// Gets the current loading state.
  bool get isLoading => state.isLoading;

  /// Gets the current error message.
  String? get errorMessage => state.hasError ? state.error.toString() : null;

  /// Gets rewards by rarity.
  List<Reward> getRewardsByRarity(RewardRarity rarity) {
    return rewards.where((reward) => reward.rarity == rarity).toList();
  }

  /// Gets common rewards.
  List<Reward> get commonRewards => getRewardsByRarity(RewardRarity.common);

  /// Gets rare rewards.
  List<Reward> get rareRewards => getRewardsByRarity(RewardRarity.rare);

  /// Gets epic rewards.
  List<Reward> get epicRewards => getRewardsByRarity(RewardRarity.epic);

  /// Gets legendary rewards.
  List<Reward> get legendaryRewards => getRewardsByRarity(RewardRarity.legendary);

  /// Gets affordable rewards for a given point amount.
  List<Reward> getAffordableRewards(int points) {
    return rewards.where((reward) => reward.pointsCost.value <= points).toList();
  }

  /// Gets rewards sorted by cost (lowest first).
  List<Reward> get rewardsSortedByCost {
    final sortedRewards = List<Reward>.from(rewards);
    sortedRewards.sort((a, b) => a.pointsCost.value.compareTo(b.pointsCost.value));
    return sortedRewards;
  }
} 