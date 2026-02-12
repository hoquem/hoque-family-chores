import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/task_completion.dart';

/// Service interface for AI rating using Gemini Vision API
abstract class AiRatingService {
  /// Get AI rating for a task photo
  /// Returns None if AI is unavailable (timeout, error, etc.)
  Future<Either<Failure, AiRating?>> rateTaskPhoto({
    required File photo,
    required String taskTitle,
    required String taskDescription,
    String? taskType,
  });
}
