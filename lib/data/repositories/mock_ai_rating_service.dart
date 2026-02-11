import 'dart:io';
import 'dart:math';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/task_completion.dart';
import '../../domain/repositories/ai_rating_service.dart';

/// Mock implementation of AiRatingService for testing
class MockAiRatingService implements AiRatingService {
  final Random _random = Random();

  // Comments grouped by rating for more realistic behavior
  final Map<int, List<String>> _commentsByRating = {
    1: [
      "Hmm, looks like this quest just started! Give it another try? 🎯",
      "Not quite there yet! But I believe in you - one more pass! 💪",
      "This photo seems more like a 'before' picture. Ready for the 'after'? 📸",
    ],
    2: [
      "Good start! Just needs a bit more work to reach greatness! 🌟",
      "You're halfway there! A little more effort and it'll be perfect! 💫",
      "Almost! Maybe give it one more quick pass? You've got this! 🚀",
    ],
    3: [
      "Nice work! Task completed successfully! 👍",
      "That'll do nicely! Quest complete! ✓",
      "Good job! The task is done and dusted! 🎉",
      "Solid effort! This quest is officially complete! 💯",
    ],
    4: [
      "Great work! This looks really good! ⭐⭐⭐⭐",
      "Impressive! You put real effort into this! 🌟",
      "Wow, that's well done! Above and beyond! 🎖️",
      "Excellent job! This is what I call quality work! 👏",
    ],
    5: [
      "INCREDIBLE! This is absolutely perfect! 🏆✨",
      "WOW! Gordon Ramsay would be proud! Five stars! ⭐⭐⭐⭐⭐",
      "Perfection achieved! You could frame this photo! 🖼️",
      "Mind. Blown. This is LEGENDARY work! 🎆🎇",
      "You've set a new standard! This is AMAZING! 🌈",
      "This deserves a standing ovation! Phenomenal! 👏👏👏",
    ],
  };

  @override
  Future<Either<Failure, AiRating?>> rateTaskPhoto({
    required File photo,
    required String taskTitle,
    required String taskDescription,
    String? taskType,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    // Random rating distribution:
    // 5%: 1 star, 10%: 2 stars, 25%: 3 stars, 35%: 4 stars, 25%: 5 stars
    final rand = _random.nextInt(100);
    final int stars;
    if (rand < 5) {
      stars = 1;
    } else if (rand < 15) {
      stars = 2;
    } else if (rand < 40) {
      stars = 3;
    } else if (rand < 75) {
      stars = 4;
    } else {
      stars = 5;
    }

    // Pick a random comment for this rating
    final comments = _commentsByRating[stars]!;
    final comment = comments[_random.nextInt(comments.length)];

    // Determine confidence based on rating
    final String confidence;
    if (stars >= 4) {
      confidence = 'high';
    } else if (stars == 3) {
      confidence = 'medium';
    } else {
      confidence = 'low';
    }

    // 1% chance of irrelevant photo (for testing)
    final relevant = _random.nextInt(100) > 1;

    return Right(
      AiRating(
        stars: stars,
        comment: comment,
        relevant: relevant,
        confidence: confidence,
        contentWarning: false,
        modelVersion: 'mock-ai-v1',
        analysisTimestamp: DateTime.now(),
      ),
    );
  }
}
