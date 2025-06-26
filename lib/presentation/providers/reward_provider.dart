import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/services/interfaces/reward_service_interface.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class RewardProvider extends ChangeNotifier {
  final RewardServiceInterface _rewardService;
  final _logger = AppLogger();
  List<Reward> _rewards = [];
  bool _isLoading = false;
  String? _errorMessage;

  RewardProvider(this._rewardService);

  List<Reward> get rewards => _rewards;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRewards(String familyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logger.d('Fetching rewards for family $familyId');
      _rewards = await _rewardService.getRewards(familyId: familyId);
      _logger.d('Fetched ${_rewards.length} rewards');

      // If no rewards exist, create a default one
      if (_rewards.isEmpty) {
        _logger.d('No rewards found, creating a default reward...');
        await createReward(
          familyId: familyId,
          name: 'Welcome Reward',
          description: 'This is your first reward! Edit or delete as needed.',
          pointsCost: 100,
          creatorId: null,
        );
        // Fetch again to update the list
        _rewards = await _rewardService.getRewards(familyId: familyId);
      }
    } catch (e, s) {
      _logger.e('Error fetching rewards: $e', error: e, stackTrace: s);
      _errorMessage = 'Error fetching rewards: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createReward({
    required String familyId,
    required String name,
    required String description,
    required int pointsCost,
    String? creatorId,
  }) async {
    try {
      _logger.d('Creating new reward for family $familyId');
      final reward = Reward(
        id: '', // Will be set by Firestore
        name: name,
        description: description,
        pointsCost: pointsCost,
        familyId: familyId,
        creatorId: creatorId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        iconName: 'card_giftcard', // Default icon
        type: RewardType.digital, // Default type
      );

      await _rewardService.createReward(familyId: familyId, reward: reward);
      _logger.d('Reward created successfully');

      // Refresh rewards list
      await fetchRewards(familyId);
    } catch (e, s) {
      _logger.e('Error creating reward: $e', error: e, stackTrace: s);
      _errorMessage = 'Error creating reward: $e';
      notifyListeners();
    }
  }

  Future<void> updateReward({
    required String familyId,
    required String rewardId,
    String? name,
    String? description,
    int? pointsCost,
  }) async {
    try {
      _logger.d('Updating reward $rewardId for family $familyId');
      final reward = _rewards.firstWhere((r) => r.id == rewardId);

      final updatedReward = reward.copyWith(
        name: name,
        description: description,
        pointsCost: pointsCost,
        updatedAt: DateTime.now(),
      );

      await _rewardService.updateReward(
        familyId: familyId,
        rewardId: rewardId,
        reward: updatedReward,
      );
      _logger.d('Reward updated successfully');

      // Refresh rewards list
      await fetchRewards(familyId);
    } catch (e, s) {
      _logger.e('Error updating reward: $e', error: e, stackTrace: s);
      _errorMessage = 'Error updating reward: $e';
      notifyListeners();
    }
  }

  Future<void> deleteReward({
    required String familyId,
    required String rewardId,
  }) async {
    try {
      _logger.d('Deleting reward $rewardId from family $familyId');
      await _rewardService.deleteReward(familyId: familyId, rewardId: rewardId);
      _logger.d('Reward deleted successfully');

      // Refresh rewards list
      await fetchRewards(familyId);
    } catch (e, s) {
      _logger.e('Error deleting reward: $e', error: e, stackTrace: s);
      _errorMessage = 'Error deleting reward: $e';
      notifyListeners();
    }
  }
}
