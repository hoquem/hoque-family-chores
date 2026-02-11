import 'dart:io';
import 'dart:math';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/task_completion.dart';
import '../../domain/repositories/ai_rating_service.dart';

/// Mock implementation of AiRatingService for testing
class MockAiRatingService implements AiRatingService {
  final Random _random = Random();

  final List<String> _funnyComments = [
    "That kitchen is SPARKLING! Gordon Ramsay would approve 👨‍🍳",
    "Wow! Did you use magic? Because that's magically clean! ✨",
    "A+ work! Your room is so tidy, I'm jealous! 🌟",
    "Nice job! Though I spotted a tiny speck... just kidding! 😄",
    "That's what I call teamwork... oh wait, you did this solo? Impressive! 💪",
    "Perfect! You could eat off that floor! (But please don't) 🍽️",
    "Good start! Maybe give it one more pass? You're almost there! 🎯",
    "Hmm, looks like someone got a bit distracted... Try again? 😅",
    "Fantastic! This quest completion brought a tear to my robot eye 🤖",
    "Excellent work! Five stars and a standing ovation! 👏",
  ];

  @override
  Future<Either<Failure, AiRating?>> rateTaskPhoto({
    required File photo,
    required String taskTitle,
    required String taskDescription,
    String? taskType,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    // Random rating between 3-5 (weighted toward good ratings)
    final stars = _random.nextInt(3) + 3;
    
    // Pick a random comment
    final comment = _funnyComments[_random.nextInt(_funnyComments.length)];

    return Right(
      AiRating(
        stars: stars,
        comment: comment,
        relevant: true,
        confidence: 'high',
        contentWarning: false,
        modelVersion: 'mock-ai-v1',
        analysisTimestamp: DateTime.now(),
      ),
    );
  }
}
