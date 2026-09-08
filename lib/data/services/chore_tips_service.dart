import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/environment_service.dart';
import '../../domain/entities/chore_guide.dart';
import '../../domain/entities/task.dart';
import '../../utils/logger.dart';

/// Service for generating tailored chore tips, motivation, and learning takeaways
/// using the Gemini API, with a robust keyword-aware fallback when offline or without API key.
class ChoreTipsService {
  final EnvironmentService _environmentService;
  final http.Client _httpClient;
  final _logger = AppLogger();

  /// In-memory cache keyed by normalized title + difficulty + parentTip
  final Map<String, ChoreGuide> _cache = {};

  ChoreTipsService({
    EnvironmentService? environmentService,
    http.Client? httpClient,
  })  : _environmentService = environmentService ?? EnvironmentService(),
        _httpClient = httpClient ?? http.Client();

  String _cacheKey(String title, TaskDifficulty difficulty, String? parentTip) {
    final cleanTitle = title.trim().toLowerCase();
    final cleanTip = parentTip?.trim().toLowerCase() ?? '';
    return '$cleanTitle|${difficulty.name}|$cleanTip';
  }

  /// Returns a cached guide if already generated in this session (0ms latency).
  ChoreGuide? getCachedGuide({
    required String title,
    TaskDifficulty difficulty = TaskDifficulty.easy,
    String? parentTip,
  }) {
    return _cache[_cacheKey(title, difficulty, parentTip)];
  }

  /// Returns an instantaneous context-aware heuristic fallback (0ms compute, no network).
  ChoreGuide getInstantFallbackGuide({
    required String title,
    String? description,
    TaskDifficulty difficulty = TaskDifficulty.easy,
    String? parentTip,
  }) {
    return _buildFallbackGuide(
      title.trim(),
      description?.trim(),
      difficulty,
      parentTip: parentTip?.trim(),
    );
  }

  /// Generates a [ChoreGuide] tailored to the given chore title, description, and difficulty.
  ///
  /// Checks cache first; uses Gemini API if available, or falls back gracefully to a curated
  /// fallback guide so chore creation is never blocked or delayed.
  Future<ChoreGuide> generateChoreGuide({
    required String title,
    String? description,
    TaskDifficulty difficulty = TaskDifficulty.easy,
    String? parentTip,
  }) async {
    final cleanTitle = title.trim();
    final cleanParentTip = parentTip?.trim();
    if (cleanTitle.isEmpty) {
      return _buildFallbackGuide(cleanTitle, description, difficulty, parentTip: cleanParentTip);
    }

    final key = _cacheKey(cleanTitle, difficulty, cleanParentTip);
    if (_cache.containsKey(key)) {
      _logger.d('ChoreTipsService: Returning cached guide for "$cleanTitle"');
      return _cache[key]!;
    }

    if (_environmentService.hasGeminiApiKey) {
      try {
        final apiKey = _environmentService.geminiApiKey;
        final guide = await _generateWithGemini(
          title: cleanTitle,
          description: description?.trim(),
          difficulty: difficulty,
          apiKey: apiKey,
          parentTip: cleanParentTip,
        );
        if (guide != null && guide.isNotEmpty) {
          final enriched = guide.copyWith(parentTip: cleanParentTip);
          _cache[key] = enriched;
          return enriched;
        }
      } catch (e, s) {
        _logger.w('Gemini chore guide generation failed, using fallback: $e',
            error: e, stackTrace: s);
      }
    }

    final fallback = _buildFallbackGuide(cleanTitle, description, difficulty, parentTip: cleanParentTip);
    _cache[key] = fallback;
    return fallback;
  }

  /// Calls Gemini REST API using structured JSON schema output
  Future<ChoreGuide?> _generateWithGemini({
    required String title,
    String? description,
    required TaskDifficulty difficulty,
    required String apiKey,
    String? parentTip,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    final promptText = '''
You are an encouraging family chore coach for kids aged 6 to 14.
Create a helpful, inspiring Mission Guide for this household chore:
- Title: "$title"
${description != null && description.isNotEmpty ? '- Details: "$description"' : ''}
- Effort Level: ${difficulty.displayName}
${parentTip != null && parentTip.isNotEmpty ? '- Home Context & Instructions from Parent: "$parentTip"\n  (IMPORTANT: Weave these home-specific details/locations/rules into the steps so they fit this exact home!)' : ''}

Requirements:
1. "motivation": A fun, high-energy pep talk or playful challenge (e.g. "Put on your favorite 3-minute hype song and race the beat!", "Channel your inner ninja").
2. "steps": 3 or 4 clear, sequential, practical steps a child can follow to get the job done right.
3. "forYou": 1-2 sentences on why completing this task is good for the child (independence, peace of mind, feeling proud in their space).
4. "forFamily": 1-2 sentences on how this helps the whole family (teamwork, lifting the load, showing care).
5. "forHome": 1-2 sentences on why this makes the home a better place (cozy, clean, welcoming environment).
6. "takeaway": The real-life skill or superpower nurtured (e.g. "Organization & Focus: Big goals are won with small, steady habits").

Tone: Warm, playful, empowering, never patronizing, and kid-appropriate.
''';

    final requestBody = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': promptText}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'motivation': {
              'type': 'STRING',
              'description': 'Playful, high-energy pep talk or challenge'
            },
            'steps': {
              'type': 'ARRAY',
              'items': {'type': 'STRING'},
              'description': '3 to 4 sequential actionable steps'
            },
            'forYou': {
              'type': 'STRING',
              'description': 'Why doing this is good for the child'
            },
            'forFamily': {
              'type': 'STRING',
              'description': 'How this helps the family'
            },
            'forHome': {
              'type': 'STRING',
              'description': 'How this benefits the home'
            },
            'takeaway': {
              'type': 'STRING',
              'description': 'Life skill or superpower takeaway'
            }
          },
          'required': [
            'motivation',
            'steps',
            'forYou',
            'forFamily',
            'forHome',
            'takeaway'
          ]
        }
      }
    };

    final response = await _httpClient
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = jsonResponse['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates.first['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts.first['text'] as String?;
          if (text != null && text.isNotEmpty) {
            final guideMap = jsonDecode(text) as Map<String, dynamic>;
            return ChoreGuide.fromMap(guideMap);
          }
        }
      }
    } else {
      _logger.w(
          'Gemini API returned status ${response.statusCode}: ${response.body}');
    }

    return null;
  }

  /// High-quality context-aware fallback when offline or Gemini API is not configured
  ChoreGuide _buildFallbackGuide(
    String title,
    String? description,
    TaskDifficulty difficulty, {
    String? parentTip,
  }) {
    final raw = _buildRawFallbackGuide(title, description, difficulty);
    return (parentTip != null && parentTip.isNotEmpty)
        ? raw.copyWith(parentTip: parentTip)
        : raw;
  }

  ChoreGuide _buildRawFallbackGuide(
    String title,
    String? description,
    TaskDifficulty difficulty,
  ) {
    final lower = title.toLowerCase();

    if (lower.contains('bed')) {
      return const ChoreGuide(
        motivation:
            'Start your day with a guaranteed win! Making your bed sets the tone for a fantastic day.',
        steps: [
          'Pull your sheets flat and straight towards the headboard',
          'Smooth out your blanket or duvet so there are no lumps',
          'Fluff up your pillow and place it proudly at the top',
        ],
        forYou:
            'Coming back to a neat bed after a long day feels cozy and welcoming.',
        forFamily:
            'It shows you take ownership of your personal space and helps keep the house tidy.',
        forHome:
            'Your bedroom instantly looks 10x tidier with just two minutes of effort.',
        takeaway:
            'Daily Habit & Discipline: Small positive habits in the morning build unstoppable momentum.',
      );
    }

    if (lower.contains('trash') ||
        lower.contains('bin') ||
        lower.contains('garbage') ||
        lower.contains('rubbish')) {
      return const ChoreGuide(
        motivation:
            'Fast mission mode! Quick footsteps, careful hands, and back inside in under 2 minutes.',
        steps: [
          'Tie up the bin bag securely so nothing spills out',
          'Carry the bag carefully to the outside wheelie bin',
          'Fit a fresh bin liner snugly into the empty bin',
        ],
        forYou:
            'A quick burst of movement gets you up and active, and the job is done in a flash.',
        forFamily:
            'Taking out the bins keeps everyone’s living space healthy and odor-free.',
        forHome:
            'Keeps the home hygienic, fresh-smelling, and clutter-free.',
        takeaway:
            'Reliability & Environmental Care: Taking responsibility for household waste protects our living space.',
      );
    }

    if (lower.contains('dish') || lower.contains('kitchen')) {
      return const ChoreGuide(
        motivation:
            'Put on your favorite 3-minute song! Can you finish before the track ends?',
        steps: [
          'Scrape leftover food into the food bin',
          'Rinse items and load plates and bowls into the dishwasher racks neatly',
          'Wipe down the sink area with a damp cloth when finished',
        ],
        forYou:
            'You learn kitchen independence and always have clean utensils ready when hungry.',
        forFamily:
            'After a meal, everyone is tired. Pitching in lifts a huge weight off the family.',
        forHome:
            'A clean sink keeps pests away and keeps the kitchen smelling fresh and clean.',
        takeaway:
            'Teamwork & Hygiene: Every household runs smoothly when everyone shares the table work.',
      );
    }

    if (lower.contains('room') ||
        lower.contains('tidy') ||
        lower.contains('clean') ||
        lower.contains('organize')) {
      return const ChoreGuide(
        motivation:
            'Tackle it in three quick zones: floor first, desk second, bed third. You got this!',
        steps: [
          'Pick up clothes and drop dirty ones in the laundry hamper',
          'Put books, toys, and gadgets back into their bins or shelves',
          'Clear any empty cups or rubbish and give surfaces a quick straighten',
        ],
        forYou:
            'A clear room equals a clear mind. It is so much easier to focus, play, and relax in an organized space.',
        forFamily:
            'Shows respect for shared living and ensures everyone feels peaceful at home.',
        forHome:
            'Prevents clutter buildup and makes the house feel spacious and inviting.',
        takeaway:
            'Spatial Organization & Focus: Knowing where everything belongs saves time and reduces stress.',
      );
    }

    if (lower.contains('laundry') ||
        lower.contains('cloth') ||
        lower.contains('fold')) {
      return const ChoreGuide(
        motivation:
            'Channel your inner department store pro! Smooth folds and neat stacks are super satisfying.',
        steps: [
          'Sort clothes by owner or type (shirts, trousers, socks)',
          'Fold shirts and trousers smoothly along the seams',
          'Pair matching socks together and put items into their designated drawers',
        ],
        forYou:
            'You will always know exactly where your favorite outfit is when you need it.',
        forFamily:
            'Laundry is a big family operation; folding your share keeps the clothing cycle moving.',
        forHome:
            'Keeps clean clothes off floors and chairs, preserving the neatness of our living spaces.',
        takeaway:
            'Self-Care & Attention to Detail: Taking care of your clothes helps them last longer and look sharper.',
      );
    }

    if (lower.contains('pet') ||
        lower.contains('dog') ||
        lower.contains('cat') ||
        lower.contains('feed')) {
      return const ChoreGuide(
        motivation:
            'Your furry friend depends on you! They appreciate your care more than words can say.',
        steps: [
          'Check the water bowl, rinse it out, and refill with fresh, cool water',
          'Measure the correct food portion into their feeding bowl',
          'Wash your hands thoroughly and give your pet a friendly head pat',
        ],
        forYou:
            'Caring for an animal builds empathy and strengthens your bond with your pet.',
        forFamily:
            'Ensures our beloved family pet is happy, healthy, and never goes hungry.',
        forHome:
            'Keeping feeding areas clean keeps ant and bug visitors away.',
        takeaway:
            'Empathy & Compassionate Responsibility: Looking after a living creature depends on steady reliability.',
      );
    }

    if (lower.contains('table') || lower.contains('set table')) {
      return const ChoreGuide(
        motivation:
            'You are the maitre d’ of family dinner! Set the scene for a wonderful meal together.',
        steps: [
          'Wipe the tabletop clean with a damp cloth',
          'Place placemats, plates, and cutlery in their proper spots',
          'Add drinking glasses and napkins for everyone attending',
        ],
        forYou:
            'Setting the table gives you a moment to slow down and get ready for a delicious meal.',
        forFamily:
            'Welcomes the whole family to sit down and connect without scrambling for forks.',
        forHome:
            'Turns mealtime into a warm, organized family tradition in the dining area.',
        takeaway:
            'Hospitality & Preparation: Thinking ahead about others’ comfort is a timeless interpersonal skill.',
      );
    }

    if (lower.contains('plant') || lower.contains('water')) {
      return const ChoreGuide(
        motivation:
            'You are the house plant guardian! Give those green leaves the refreshing drink they need.',
        steps: [
          'Fill your watering can with room-temperature water',
          'Gently pour water at the soil base until moist, without flooding the pot',
          'Wipe away any water drips from the saucer or furniture',
        ],
        forYou:
            'Watching plants thrive and grow green leaves under your care is genuinely rewarding.',
        forFamily:
            'Indoor plants clean the air we breathe and make the family home vibrant.',
        forHome:
            'Healthy plants bring life, color, and natural beauty to every room.',
        takeaway:
            'Nurturing & Patience: Growth takes time, consistency, and gentle care.',
      );
    }

    // Universal default
    return ChoreGuide(
      motivation:
          'Every great hero takes pride in their space. Knock this mission out and claim your stars!',
      steps: [
        'Gather any supplies or tools you need before you begin',
        'Focus on completing one part of "$title" carefully at a time',
        'Do a final 30-second inspection to make sure nothing was missed',
      ],
      forYou:
          'Finishing what you set out to do builds confidence and self-trust.',
      forFamily:
          'Teamwork makes the household run smoothly and shows love in action.',
      forHome:
          'Taking care of our home keeps it a peaceful, cozy haven for all of us.',
      takeaway:
          'Diligence & Ownership: Seeing a job through from start to finish is a superpower for life.',
    );
  }
}
