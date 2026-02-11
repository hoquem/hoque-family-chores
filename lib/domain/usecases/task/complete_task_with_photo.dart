import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/task_completion.dart';
import '../../repositories/ai_rating_service.dart';
import '../../repositories/task_completion_repository.dart';
import '../../value_objects/task_id.dart';
import '../../value_objects/user_id.dart';

/// Use case for completing a task with photo proof
class CompleteTaskWithPhoto {
  final TaskCompletionRepository completionRepository;
  final AiRatingService aiRatingService;

  CompleteTaskWithPhoto({
    required this.completionRepository,
    required this.aiRatingService,
  });

  /// Execute the use case
  Future<Either<Failure, TaskCompletion>> call({
    required TaskId taskId,
    required UserId userId,
    required File photo,
    required String taskTitle,
    required String taskDescription,
    String? taskType,
  }) async {
    // 1. Upload photo to storage
    final uploadResult = await completionRepository.uploadPhoto(
      photo: photo,
      taskId: taskId,
      userId: userId,
    );

    return uploadResult.fold(
      (failure) => Left(failure),
      (photoUrl) async {
        // 2. Get AI rating (with timeout and error handling)
        AiRating? aiRating;
        final aiResult = await aiRatingService.rateTaskPhoto(
          photo: photo,
          taskTitle: taskTitle,
          taskDescription: taskDescription,
          taskType: taskType,
        );

        // If AI rating succeeds, use it; otherwise continue without it
        aiResult.fold(
          (failure) {
            // Log failure but don't block completion
            aiRating = null;
          },
          (rating) {
            aiRating = rating;
          },
        );

        // 3. Create completion record
        final completionResult = await completionRepository.createCompletion(
          taskId: taskId,
          userId: userId,
          photoUrl: photoUrl,
          aiRating: aiRating,
        );

        return completionResult;
      },
    );
  }
}
