import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import '../../core/error/failures.dart';
import '../../domain/entities/task_completion.dart';
import '../../domain/repositories/ai_rating_service.dart';

/// Gemini Vision API implementation of AiRatingService
class GeminiAiRatingService implements AiRatingService {
  final String apiKey;
  final String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  final Duration timeout;

  GeminiAiRatingService({
    required this.apiKey,
    this.timeout = const Duration(seconds: 10),
  });

  @override
  Future<Either<Failure, AiRating?>> rateTaskPhoto({
    required File photo,
    required String taskTitle,
    required String taskDescription,
    String? taskType,
  }) async {
    try {
      // Read and encode photo
      final bytes = await photo.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Build prompt
      final prompt = _buildPrompt(taskTitle, taskDescription, taskType ?? 'general');

      // Build request
      final request = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 200,
          'responseMimeType': 'application/json',
        }
      };

      // Call Gemini API
      final response = await http
          .post(
            Uri.parse('$baseUrl/gemini-2.0-flash-exp:generateContent?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(request),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Extract text from response
        final text = responseData['candidates'][0]['content']['parts'][0]['text'] as String;
        final aiResponse = json.decode(text);

        // Parse response
        return Right(
          AiRating(
            stars: aiResponse['stars'] as int,
            comment: aiResponse['comment'] as String,
            relevant: aiResponse['relevant'] as bool? ?? true,
            confidence: aiResponse['confidence'] as String? ?? 'medium',
            contentWarning: aiResponse['contentWarning'] as bool? ?? false,
            modelVersion: 'gemini-2.0-flash-exp',
            analysisTimestamp: DateTime.now(),
          ),
        );
      } else if (response.statusCode == 429) {
        // Rate limit - return null (graceful degradation)
        return const Right(null);
      } else {
        // Other errors - return null (graceful degradation)
        return const Right(null);
      }
    } on TimeoutException {
      // Timeout - return null (graceful degradation)
      return const Right(null);
    } catch (e) {
      // Any other error - return null (graceful degradation)
      return const Right(null);
    }
  }

  String _buildPrompt(String taskTitle, String taskDescription, String taskType) {
    return '''You are a friendly AI assistant helping a family manage household chores (called "quests"). A family member has just completed a quest and taken a photo as proof.

**Quest Details:**
- Quest Name: $taskTitle
- Quest Description: $taskDescription
- Quest Type: $taskType

**Your Task:**
Analyze the photo and provide:
1. A rating from 1 to 5 stars based on how well the task appears to be completed
2. A fun, encouraging comment (1-2 sentences max)
3. Whether the photo seems relevant to the quest

**Rating Guidelines:**
- ⭐ (1 star): Task barely started or photo doesn't show the task
- ⭐⭐ (2 stars): Task partially done, needs more work
- ⭐⭐⭐ (3 stars): Task completed adequately
- ⭐⭐⭐⭐ (4 stars): Task done well, good effort
- ⭐⭐⭐⭐⭐ (5 stars): Task done exceptionally well

**Comment Tone:**
- Be encouraging and positive, even for low ratings
- Use emojis sparingly (1-2 max)
- Reference the specific quest when possible
- If 1-2 stars: be constructive, not critical ("Almost there! Maybe give it one more pass?")
- If 3-5 stars: celebrate the achievement ("Wow, that's spotless!")
- If photo seems unrelated: be playful, not accusatory ("Hmm, looks more like a selfie than a clean room 😄")

**Inappropriate Content:**
If the photo contains inappropriate content (NSFW, offensive, dangerous), respond with:
- stars: 0
- comment: "This photo can't be used. Please take a new photo of your completed task."
- relevant: false
- contentWarning: true

**Response Format (JSON only):**
{
  "stars": <number 1-5>,
  "comment": "<your fun, encouraging comment>",
  "relevant": <true if photo relates to quest, false if unrelated>,
  "confidence": <"high"|"medium"|"low">,
  "contentWarning": <true if inappropriate, false otherwise>
}

Now analyze this photo for the quest "$taskTitle":''';
  }
}
