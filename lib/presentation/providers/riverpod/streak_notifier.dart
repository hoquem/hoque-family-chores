import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/domain/entities/streak.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/usecases/streak/update_streak_usecase.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';

part 'streak_notifier.g.dart';

/// Manages streak-related state and operations.
/// 
/// This notifier handles loading and updating user streaks,
/// including milestone achievements and freeze management.
/// 
/// Example:
/// ```dart
/// final streakAsync = ref.watch(streakNotifierProvider(userId));
/// final notifier = ref.read(streakNotifierProvider(userId).notifier);
/// await notifier.updateStreakAfterQuestCompletion(DateTime.now());
/// ```
@riverpod
class StreakNotifier extends _$StreakNotifier {
  final _logger = AppLogger();

  @override
  Stream<Streak?> build(UserId userId) {
    _logger.d('StreakNotifier: Building stream for user $userId');
    
    try {
      final streakRepository = ref.watch(streakRepositoryProvider);
      return streakRepository.streamStreak(userId);
    } catch (e) {
      _logger.e('StreakNotifier: Error loading streak', error: e);
      throw Exception('Failed to load streak: $e');
    }
  }

  /// Updates streak after quest completion
  Future<StreakUpdateResult?> updateStreakAfterQuestCompletion(
    DateTime completionDate,
  ) async {
    _logger.d('StreakNotifier: Updating streak after quest completion');
    
    try {
      final updateStreakUseCase = ref.read(updateStreakUseCaseProvider);
      final userId = state.value?.userId ?? this.userId;
      
      final result = await updateStreakUseCase.call(
        userId: userId,
        completionDate: completionDate,
      );
      
      return result.fold(
        (failure) {
          _logger.e('StreakNotifier: Failed to update streak', error: failure.message);
          throw Exception(failure.message);
        },
        (updateResult) {
          _logger.d('StreakNotifier: Streak updated successfully');
          ref.invalidateSelf(); // Refresh the stream
          return updateResult;
        },
      );
    } catch (e) {
      _logger.e('StreakNotifier: Error updating streak', error: e);
      rethrow;
    }
  }

  /// Purchases a streak freeze with stars
  Future<void> purchaseFreeze() async {
    _logger.d('StreakNotifier: Purchasing streak freeze');
    
    try {
      final streakRepository = ref.read(streakRepositoryProvider);
      final userId = state.value?.userId ?? this.userId;
      
      await streakRepository.purchaseFreeze(userId);
      ref.invalidateSelf();
      _logger.d('StreakNotifier: Freeze purchased successfully');
    } catch (e) {
      _logger.e('StreakNotifier: Error purchasing freeze', error: e);
      throw Exception('Failed to purchase freeze: $e');
    }
  }

  /// Gets the current streak or null if loading/error
  Streak? get currentStreak => state.value;

  /// Gets the current loading state
  bool get isLoading => state.isLoading;

  /// Gets the current error message
  String? get errorMessage => state.hasError ? state.error.toString() : null;

  /// Checks if user has an active streak
  bool get hasActiveStreak => currentStreak?.hasActiveStreak ?? false;

  /// Gets current streak count
  int get streakCount => currentStreak?.currentStreak ?? 0;

  /// Gets longest streak count
  int get longestStreakCount => currentStreak?.longestStreak ?? 0;

  /// Gets available freezes
  int get freezesAvailable => currentStreak?.freezesAvailable ?? 0;

  /// Gets streak state for UI
  StreakState get streakState => currentStreak?.state ?? StreakState.none;
}
