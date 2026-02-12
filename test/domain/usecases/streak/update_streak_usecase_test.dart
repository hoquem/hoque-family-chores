import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:hoque_family_chores/domain/entities/streak.dart';
import 'package:hoque_family_chores/domain/repositories/streak_repository.dart';
import 'package:hoque_family_chores/domain/repositories/user_repository.dart';
import 'package:hoque_family_chores/domain/usecases/streak/update_streak_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';

@GenerateMocks([StreakRepository, UserRepository])
import 'update_streak_usecase_test.mocks.dart';

void main() {
  late UpdateStreakUseCase useCase;
  late MockStreakRepository mockStreakRepository;
  late MockUserRepository mockUserRepository;
  late UserId userId;

  setUp(() {
    mockStreakRepository = MockStreakRepository();
    mockUserRepository = MockUserRepository();
    useCase = UpdateStreakUseCase(mockStreakRepository, mockUserRepository);
    userId = UserId('test-user-123');
  });

  group('UpdateStreakUseCase', () {
    test('should create and increment streak on first quest completion', () async {
      // Arrange
      final completionDate = DateTime.now();
      final newStreak = Streak.initial(userId).copyWith(
        currentStreak: 1,
        longestStreak: 1,
        lastCompletedDate: completionDate,
      );

      when(mockStreakRepository.getStreak(userId))
          .thenAnswer((_) async => null);
      when(mockStreakRepository.incrementStreak(userId, completionDate))
          .thenAnswer((_) async => newStreak);

      // Act
      final result = await useCase.call(
        userId: userId,
        completionDate: completionDate,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return Right'),
        (updateResult) {
          expect(updateResult.streak.currentStreak, 1);
          expect(updateResult.streakIncremented, isTrue);
          expect(updateResult.milestoneReached, isNull);
        },
      );

      verify(mockStreakRepository.getStreak(userId)).called(1);
      verify(mockStreakRepository.incrementStreak(userId, completionDate))
          .called(1);
    });

    test('should not increment streak if quest already completed today', () async {
      // Arrange
      final today = DateTime.now();
      final existingStreak = Streak.initial(userId).copyWith(
        currentStreak: 5,
        longestStreak: 5,
        lastCompletedDate: today,
      );

      when(mockStreakRepository.getStreak(userId))
          .thenAnswer((_) async => existingStreak);

      // Act
      final result = await useCase.call(
        userId: userId,
        completionDate: today,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return Right'),
        (updateResult) {
          expect(updateResult.streak.currentStreak, 5);
          expect(updateResult.streakIncremented, isFalse);
        },
      );

      verify(mockStreakRepository.getStreak(userId)).called(1);
      verifyNever(mockStreakRepository.incrementStreak(any, any));
    });

    test('should increment streak on consecutive day', () async {
      // Arrange
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final today = DateTime.now();
      final existingStreak = Streak.initial(userId).copyWith(
        currentStreak: 5,
        longestStreak: 5,
        lastCompletedDate: yesterday,
      );
      final updatedStreak = existingStreak.copyWith(
        currentStreak: 6,
        longestStreak: 6,
        lastCompletedDate: today,
      );

      when(mockStreakRepository.getStreak(userId))
          .thenAnswer((_) async => existingStreak);
      when(mockStreakRepository.incrementStreak(userId, today))
          .thenAnswer((_) async => updatedStreak);

      // Act
      final result = await useCase.call(
        userId: userId,
        completionDate: today,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return Right'),
        (updateResult) {
          expect(updateResult.streak.currentStreak, 6);
          expect(updateResult.streakIncremented, isTrue);
        },
      );

      verify(mockStreakRepository.incrementStreak(userId, today)).called(1);
    });

    test('should award milestone bonus when reaching milestone', () async {
      // Arrange
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final today = DateTime.now();
      final existingStreak = Streak.initial(userId).copyWith(
        currentStreak: 6,
        longestStreak: 6,
        lastCompletedDate: yesterday,
        milestonesAchieved: [],
      );
      final updatedStreak = existingStreak.copyWith(
        currentStreak: 7,
        longestStreak: 7,
        lastCompletedDate: today,
      );

      when(mockStreakRepository.getStreak(userId))
          .thenAnswer((_) async => existingStreak);
      when(mockStreakRepository.incrementStreak(userId, today))
          .thenAnswer((_) async => updatedStreak);
      when(mockStreakRepository.awardMilestoneBonus(userId, 7, 50))
          .thenAnswer((_) async {});
      when(mockUserRepository.addPoints(userId, Points(50)))
          .thenAnswer((_) async {});

      // Act
      final result = await useCase.call(
        userId: userId,
        completionDate: today,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return Right'),
        (updateResult) {
          expect(updateResult.streak.currentStreak, 7);
          expect(updateResult.milestoneReached, isNotNull);
          expect(updateResult.milestoneReached?.days, 7);
          expect(updateResult.milestoneReached?.starReward, 50);
        },
      );

      verify(mockStreakRepository.awardMilestoneBonus(userId, 7, 50)).called(1);
      verify(mockUserRepository.addPoints(userId, Points(50))).called(1);
    });

    test('should use freeze when missing a day with freeze available', () async {
      // Arrange
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final today = DateTime.now();
      final existingStreak = Streak.initial(userId).copyWith(
        currentStreak: 5,
        longestStreak: 5,
        lastCompletedDate: twoDaysAgo,
        freezesAvailable: 1,
      );
      final frozenStreak = existingStreak.copyWith(freezesAvailable: 0);

      when(mockStreakRepository.getStreak(userId))
          .thenAnswer((_) async => existingStreak);
      when(mockStreakRepository.useFreeze(userId))
          .thenAnswer((_) async => frozenStreak);

      // Act
      final result = await useCase.call(
        userId: userId,
        completionDate: today,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return Right'),
        (updateResult) {
          expect(updateResult.freezeUsed, isTrue);
          expect(updateResult.streak.freezesAvailable, 0);
        },
      );

      verify(mockStreakRepository.useFreeze(userId)).called(1);
    });

    test('should reset streak when missing day without freeze', () async {
      // Arrange
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final today = DateTime.now();
      final existingStreak = Streak.initial(userId).copyWith(
        currentStreak: 5,
        longestStreak: 10,
        lastCompletedDate: twoDaysAgo,
        freezesAvailable: 0,
      );
      final resetStreak = existingStreak.copyWith(
        currentStreak: 0,
        lastCompletedDate: null,
      );
      final newStreak = resetStreak.copyWith(
        currentStreak: 1,
        lastCompletedDate: today,
      );

      when(mockStreakRepository.getStreak(userId))
          .thenAnswer((_) async => existingStreak);
      when(mockStreakRepository.resetStreak(userId))
          .thenAnswer((_) async => resetStreak);
      when(mockStreakRepository.incrementStreak(userId, today))
          .thenAnswer((_) async => newStreak);

      // Act
      final result = await useCase.call(
        userId: userId,
        completionDate: today,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return Right'),
        (updateResult) {
          expect(updateResult.streakBroken, isTrue);
          expect(updateResult.previousStreak, 5);
          expect(updateResult.streak.currentStreak, 1);
        },
      );

      verify(mockStreakRepository.resetStreak(userId)).called(1);
      verify(mockStreakRepository.incrementStreak(userId, today)).called(1);
    });
  });
}
