import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/entities/task_completion.dart';
import 'package:hoque_family_chores/domain/repositories/ai_rating_service.dart';
import 'package:hoque_family_chores/domain/repositories/task_completion_repository.dart';
import 'package:hoque_family_chores/domain/usecases/task/complete_task_with_photo.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

// Mocks
class MockTaskCompletionRepository extends Mock
    implements TaskCompletionRepository {}

class MockAiRatingService extends Mock implements AiRatingService {}

class MockFile extends Mock implements File {}

void main() {
  late CompleteTaskWithPhoto useCase;
  late MockTaskCompletionRepository mockCompletionRepository;
  late MockAiRatingService mockAiRatingService;
  late MockFile mockPhoto;

  setUp(() {
    mockCompletionRepository = MockTaskCompletionRepository();
    mockAiRatingService = MockAiRatingService();
    mockPhoto = MockFile();
    useCase = CompleteTaskWithPhoto(
      completionRepository: mockCompletionRepository,
      aiRatingService: mockAiRatingService,
    );

    // Register fallback values for mocktail
    registerFallbackValue(mockPhoto);
    registerFallbackValue(TaskId('test-task-id'));
    registerFallbackValue(UserId('test-user-id'));
  });

  group('CompleteTaskWithPhoto', () {
    final taskId = TaskId('task-123');
    final userId = UserId('user-456');
    const taskTitle = 'Clean Kitchen';
    const taskDescription = 'Wash dishes and wipe counters';
    const photoUrl = 'https://storage.example.com/photo.jpg';

    final aiRating = AiRating(
      stars: 4,
      comment: 'Great work!',
      relevant: true,
      confidence: 'high',
      contentWarning: false,
      modelVersion: 'gemini-2.5-flash',
      analysisTimestamp: DateTime.now(),
    );

    final completion = TaskCompletion(
      id: 'completion-1',
      taskId: taskId,
      userId: userId,
      timestamp: DateTime.now(),
      photoUrl: photoUrl,
      status: TaskCompletionStatus.pendingApproval,
      aiRating: aiRating,
    );

    test('should successfully complete task with AI rating', () async {
      // Arrange
      when(() => mockCompletionRepository.uploadPhoto(
            photo: any(named: 'photo'),
            taskId: any(named: 'taskId'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => const Right(photoUrl));

      when(() => mockAiRatingService.rateTaskPhoto(
            photo: any(named: 'photo'),
            taskTitle: any(named: 'taskTitle'),
            taskDescription: any(named: 'taskDescription'),
            taskType: any(named: 'taskType'),
          )).thenAnswer((_) async => Right(aiRating));

      when(() => mockCompletionRepository.createCompletion(
            taskId: any(named: 'taskId'),
            userId: any(named: 'userId'),
            photoUrl: any(named: 'photoUrl'),
            aiRating: any(named: 'aiRating'),
          )).thenAnswer((_) async => Right(completion));

      // Act
      final result = await useCase(
        taskId: taskId,
        userId: userId,
        photo: mockPhoto,
        taskTitle: taskTitle,
        taskDescription: taskDescription,
      );

      // Assert
      expect(result, isA<Right<Failure, TaskCompletion>>());
      result.fold(
        (failure) => fail('Expected Right, got Left: $failure'),
        (comp) {
          expect(comp.id, completion.id);
          expect(comp.photoUrl, photoUrl);
          expect(comp.aiRating, isNotNull);
          expect(comp.aiRating!.stars, 4);
        },
      );

      verify(() => mockCompletionRepository.uploadPhoto(
            photo: mockPhoto,
            taskId: taskId,
            userId: userId,
          )).called(1);
      verify(() => mockAiRatingService.rateTaskPhoto(
            photo: mockPhoto,
            taskTitle: taskTitle,
            taskDescription: taskDescription,
            taskType: null,
          )).called(1);
    });

    test('should complete task without AI rating when AI service fails',
        () async {
      // Arrange
      when(() => mockCompletionRepository.uploadPhoto(
            photo: any(named: 'photo'),
            taskId: any(named: 'taskId'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => const Right(photoUrl));

      when(() => mockAiRatingService.rateTaskPhoto(
            photo: any(named: 'photo'),
            taskTitle: any(named: 'taskTitle'),
            taskDescription: any(named: 'taskDescription'),
            taskType: any(named: 'taskType'),
          )).thenAnswer((_) async => const Left(ServerFailure('AI timeout')));

      final completionWithoutAi = TaskCompletion(
        id: 'completion-2',
        taskId: taskId,
        userId: userId,
        timestamp: DateTime.now(),
        photoUrl: photoUrl,
        status: TaskCompletionStatus.pendingApproval,
        aiRating: null,
      );

      when(() => mockCompletionRepository.createCompletion(
            taskId: any(named: 'taskId'),
            userId: any(named: 'userId'),
            photoUrl: any(named: 'photoUrl'),
            aiRating: null,
          )).thenAnswer((_) async => Right(completionWithoutAi));

      // Act
      final result = await useCase(
        taskId: taskId,
        userId: userId,
        photo: mockPhoto,
        taskTitle: taskTitle,
        taskDescription: taskDescription,
      );

      // Assert
      expect(result, isA<Right<Failure, TaskCompletion>>());
      result.fold(
        (failure) => fail('Expected Right, got Left: $failure'),
        (comp) {
          expect(comp.photoUrl, photoUrl);
          expect(comp.aiRating, isNull);
        },
      );
    });

    test('should reject photo when AI detects inappropriate content',
        () async {
      // Arrange
      when(() => mockCompletionRepository.uploadPhoto(
            photo: any(named: 'photo'),
            taskId: any(named: 'taskId'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => const Right(photoUrl));

      final inappropriateRating = AiRating(
        stars: 0,
        comment: 'Content not appropriate',
        relevant: false,
        confidence: 'high',
        contentWarning: true,
        modelVersion: 'gemini-2.5-flash',
        analysisTimestamp: DateTime.now(),
      );

      when(() => mockAiRatingService.rateTaskPhoto(
            photo: any(named: 'photo'),
            taskTitle: any(named: 'taskTitle'),
            taskDescription: any(named: 'taskDescription'),
            taskType: any(named: 'taskType'),
          )).thenAnswer((_) async => Right(inappropriateRating));

      // Act
      final result = await useCase(
        taskId: taskId,
        userId: userId,
        photo: mockPhoto,
        taskTitle: taskTitle,
        taskDescription: taskDescription,
      );

      // Assert
      expect(result, isA<Left<Failure, TaskCompletion>>());
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('cannot be used'));
        },
        (comp) => fail('Expected Left, got Right'),
      );

      // Should not create completion when content warning detected
      verifyNever(() => mockCompletionRepository.createCompletion(
            taskId: any(named: 'taskId'),
            userId: any(named: 'userId'),
            photoUrl: any(named: 'photoUrl'),
            aiRating: any(named: 'aiRating'),
          ));
    });

    test('should return failure when photo upload fails', () async {
      // Arrange
      when(() => mockCompletionRepository.uploadPhoto(
            photo: any(named: 'photo'),
            taskId: any(named: 'taskId'),
            userId: any(named: 'userId'),
          )).thenAnswer(
          (_) async => const Left(ServerFailure('Upload failed')));

      // Act
      final result = await useCase(
        taskId: taskId,
        userId: userId,
        photo: mockPhoto,
        taskTitle: taskTitle,
        taskDescription: taskDescription,
      );

      // Assert
      expect(result, isA<Left<Failure, TaskCompletion>>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Upload failed');
        },
        (comp) => fail('Expected Left, got Right'),
      );

      // Should not call AI service if upload fails
      verifyNever(() => mockAiRatingService.rateTaskPhoto(
            photo: any(named: 'photo'),
            taskTitle: any(named: 'taskTitle'),
            taskDescription: any(named: 'taskDescription'),
            taskType: any(named: 'taskType'),
          ));
    });

    test('should return failure when completion creation fails', () async {
      // Arrange
      when(() => mockCompletionRepository.uploadPhoto(
            photo: any(named: 'photo'),
            taskId: any(named: 'taskId'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => const Right(photoUrl));

      when(() => mockAiRatingService.rateTaskPhoto(
            photo: any(named: 'photo'),
            taskTitle: any(named: 'taskTitle'),
            taskDescription: any(named: 'taskDescription'),
            taskType: any(named: 'taskType'),
          )).thenAnswer((_) async => Right(aiRating));

      when(() => mockCompletionRepository.createCompletion(
            taskId: any(named: 'taskId'),
            userId: any(named: 'userId'),
            photoUrl: any(named: 'photoUrl'),
            aiRating: any(named: 'aiRating'),
          )).thenAnswer(
          (_) async =>
              const Left(ServerFailure('Failed to create completion')));

      // Act
      final result = await useCase(
        taskId: taskId,
        userId: userId,
        photo: mockPhoto,
        taskTitle: taskTitle,
        taskDescription: taskDescription,
      );

      // Assert
      expect(result, isA<Left<Failure, TaskCompletion>>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('create completion'));
        },
        (comp) => fail('Expected Left, got Right'),
      );
    });
  });
}
