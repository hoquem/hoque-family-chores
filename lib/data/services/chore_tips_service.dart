import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import '../../domain/entities/chore_guide.dart';
import '../../domain/entities/task.dart';
import '../../utils/logger.dart';

/// Service for generating tailored chore tips, motivation, and learning takeaways.
///
/// Calls the secure server-side Cloud Function [generateChoreGuide] when online,
/// and falls back instantly to rich keyword-aware local guides when offline or
/// before network responses arrive.
class ChoreTipsService {
  final FirebaseFunctions? _override;
  final _logger = AppLogger();

  /// In-memory cache keyed by normalized title + difficulty + parentTip
  final Map<String, ChoreGuide> _cache = {};

  ChoreTipsService({
    FirebaseFunctions? functions,
  }) : _override = functions;

  FirebaseFunctions? get _functions {
    if (_override != null) return _override;
    try {
      return FirebaseFunctions.instance;
    } catch (_) {
      return null;
    }
  }

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
  /// Checks cache first; uses server-side Gemini Cloud Function if available, or falls back
  /// gracefully to a curated local guide so chore creation is never blocked or delayed.
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

    try {
      final guide = await _generateWithCloudFunction(
        title: cleanTitle,
        description: description?.trim(),
        difficulty: difficulty,
        parentTip: cleanParentTip,
      );
      if (guide != null && guide.isNotEmpty) {
        final enriched = guide.copyWith(parentTip: cleanParentTip);
        _cache[key] = enriched;
        return enriched;
      }
    } catch (e, s) {
      _logger.w('Cloud Function guide generation threw error, using fallback: $e',
          error: e, stackTrace: s);
    }

    final fallback = _buildFallbackGuide(cleanTitle, description, difficulty, parentTip: cleanParentTip);
    _cache[key] = fallback;
    return fallback;
  }

  /// Calls the secure server-side Cloud Function [generateChoreGuide]
  Future<ChoreGuide?> _generateWithCloudFunction({
    required String title,
    String? description,
    required TaskDifficulty difficulty,
    String? parentTip,
  }) async {
    final functions = _functions;
    if (functions == null) return null;

    try {
      final callable = functions.httpsCallable(
        'generateChoreGuide',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 8)),
      );
      final result = await callable.call<dynamic>({
        'title': title,
        'description': description ?? '',
        'difficulty': difficulty.name,
        'parentTip': parentTip ?? '',
      });

      final data = (result.data as Map?)?.cast<String, dynamic>() ??
          Map<String, dynamic>.from(result.data as Map);
      return ChoreGuide.fromMap(data);
    } catch (e, s) {
      _logger.w('Cloud Function chore guide generation failed, using fallback: $e',
          error: e, stackTrace: s);
      return null;
    }
  }

  /// High-quality context-aware fallback when offline or before server returns
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

  bool _containsAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  ChoreGuide _buildRawFallbackGuide(
    String title,
    String? description,
    TaskDifficulty difficulty,
  ) {
    final combined = '${title.toLowerCase()} ${description?.toLowerCase() ?? ''}';

    // 1. Trash / Bins / Recycling (checked first so room trash like "kitchen trash" gets trash steps)
    if (_containsAny(combined, [
      'trash',
      'bin',
      'bins',
      'rubbish',
      'garbage',
      'recycling',
      'waste',
    ])) {
      return const ChoreGuide(
        motivation:
            'Fast mission mode! Quick footsteps, careful hands, and back inside in under 2 minutes.',
        steps: [
          'Tie up the bin bag securely so nothing spills out',
          'Carry the bag carefully to the outside wheelie or collection bin',
          'Fit a fresh bin liner snugly into the empty bin',
        ],
        forYou:
            'A quick burst of movement gets you active, and the job is done in a flash.',
        forFamily:
            'Taking out the bins keeps everyone’s living space healthy and odor-free.',
        forHome:
            'Keeps the home hygienic, fresh-smelling, and clutter-free.',
        takeaway:
            'Reliability & Environmental Care: Taking responsibility for household waste protects our living space.',
      );
    }

    // 2. Bathroom / Toilet / Washroom
    if (_containsAny(combined, [
      'bathroom',
      'bath',
      'toilet',
      'shower',
      'loo',
      'sink',
      'basin',
      'restroom',
      'washroom',
      'wc',
    ])) {
      return const ChoreGuide(
        motivation:
            'Sparkle mission! Transform the bathroom into a fresh, gleaming five-star spa.',
        steps: [
          'Put dirty towels and bath mats into the laundry basket',
          'Wipe down the sink and faucets with a damp cloth until shiny',
          'Wipe the counter and toilet seat with bathroom wipes (wash hands after!)',
          'Empty the small bathroom bin and check that toilet paper is stocked',
        ],
        forYou:
            'Using a sparkling, clean bathroom makes you feel refreshed, healthy, and proud.',
        forFamily:
            'Shared bathrooms get busy; keeping yours clean is a big gift of care for everyone.',
        forHome:
            'Regular bathroom care prevents soap scum, mildew, and keeps hygiene top-notch.',
        takeaway:
            'Hygiene & Sanitation: Keeping personal care spaces clean protects everyone’s health.',
      );
    }

    // 3. Kitchen / Dishes
    if (_containsAny(combined, [
      'dish',
      'dishes',
      'dishwasher',
      'kitchen',
      'plate',
      'cutlery',
      'pot',
      'pan',
      'cook',
    ])) {
      return const ChoreGuide(
        motivation:
            'Put on your favorite 3-minute song! Can you finish before the track ends?',
        steps: [
          'Scrape leftover food into the food bin',
          'Rinse items and load plates and bowls into the dishwasher racks neatly',
          'Wipe down the kitchen counters and sink area with a damp cloth',
        ],
        forYou:
            'You learn kitchen independence and always have clean utensils ready when hungry.',
        forFamily:
            'After a meal, everyone is tired. Pitching in lifts a huge weight off the family.',
        forHome:
            'A clean sink and clear counters keep pests away and the kitchen smelling fresh.',
        takeaway:
            'Teamwork & Hygiene: Every household runs smoothly when everyone shares the table work.',
      );
    }

    // 4. Floor / Vacuum / Mop / Sweep
    if (_containsAny(combined, [
      'vacuum',
      'hoover',
      'mop',
      'sweep',
      'sweeping',
      'broom',
      'carpet',
      'rug',
    ])) {
      return const ChoreGuide(
        motivation:
            'Time to pave the runway! Smooth, straight lines leave satisfying tracks on the floor.',
        steps: [
          'Pick up any loose cables, shoes, or toys off the floor first',
          'Start from the farthest corner and work backwards towards the door',
          'Empty the vacuum dust container or rinse out the mop head when done',
        ],
        forYou:
            'Walking barefoot on a clean, crumb-free floor feels amazing.',
        forFamily:
            'Clear floors keep walkways safe from tripping and keep dust away for everyone.',
        forHome:
            'Caring for carpets and hard floors extends their life and keeps the house looking pristine.',
        takeaway:
            'Thoroughness & Technique: Working in structured lines gets better results in half the time.',
      );
    }

    // 5. Bedroom / Bed
    if (_containsAny(combined, [
      'bed',
      'bedroom',
      'pillow',
      'sheets',
      'duvet',
      'blanket',
      'mattress',
    ])) {
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

    // 6. Laundry / Clothes / Folding
    if (_containsAny(combined, [
      'laundry',
      'cloth',
      'clothes',
      'fold',
      'folding',
      'iron',
      'sock',
      'socks',
      'wardrobe',
    ])) {
      return const ChoreGuide(
        motivation:
            'Channel your inner department store pro! Smooth folds and neat stacks are super satisfying.',
        steps: [
          'Sort clothes by type (shirts, trousers, socks, underwear)',
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

    // 7. Pets / Animals
    if (_containsAny(combined, [
      'pet',
      'pets',
      'dog',
      'cat',
      'puppy',
      'kitten',
      'fish',
      'hamster',
      'bird',
      'litter',
      'leash',
      'feed',
    ])) {
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

    // 8. Dining / Table
    if (_containsAny(combined, [
      'table',
      'dining',
      'placemat',
      'napkin',
    ])) {
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

    // 9. Plants / Garden / Outdoor
    if (_containsAny(combined, [
      'plant',
      'plants',
      'garden',
      'gardening',
      'yard',
      'lawn',
      'weed',
      'flower',
      'flowers',
      'water',
    ])) {
      return const ChoreGuide(
        motivation:
            'You are the house plant guardian! Give those green leaves the refreshing drink they need.',
        steps: [
          'Fill your watering can with room-temperature water',
          'Gently pour water at the soil base until moist, without flooding the pot',
          'Wipe away any water drips from the saucer or surrounding floor',
        ],
        forYou:
            'Watching plants thrive and grow green leaves under your care is genuinely rewarding.',
        forFamily:
            'Indoor and garden plants freshen the air we breathe and make our home vibrant.',
        forHome:
            'Healthy plants bring life, color, and natural beauty to every room.',
        takeaway:
            'Nurturing & Patience: Growth takes time, consistency, and gentle care.',
      );
    }

    // 10. Tidy / Organize / Declutter
    if (_containsAny(combined, [
      'tidy',
      'organize',
      'declutter',
      'pack away',
      'toy',
      'toys',
      'shelf',
      'bookshelf',
    ])) {
      return const ChoreGuide(
        motivation:
            'Zone blitz! Divide the space into sections and tackle one spot at a time.',
        steps: [
          'Pick up loose items off the floor and sort them into piles',
          'Put items back into their designated boxes, shelves, or drawers',
          'Do a quick 30-second scan to ensure pathways are clear and surfaces look neat',
        ],
        forYou:
            'An organized space clears your mind and makes it easy to find everything you need.',
        forFamily:
            'Keeps shared spaces calm and welcoming for everyone to enjoy.',
        forHome:
            'Prevents clutter buildup and makes the whole house feel open and calm.',
        takeaway:
            'Spatial Organization: Having a home for everything saves time and eliminates stress.',
      );
    }

    // 11. General Clean / Wipe / Dust
    if (_containsAny(combined, [
      'clean',
      'wipe',
      'dust',
      'wash',
      'polish',
      'sanitize',
      'sponge',
    ])) {
      return const ChoreGuide(
        motivation:
            'Put on your cleaning detective hat! Hunt down dust and leave every surface gleaming.',
        steps: [
          'Gather your cloth or duster and any safe spray recommended by a parent',
          'Wipe surfaces from top to bottom so dust falls downwards',
          'Check corners, edges, and handles to ensure nothing was missed',
        ],
        forYou:
            'Working in a clean, fresh space gives you energy and peace of mind.',
        forFamily:
            'Keeping surfaces clean and fresh helps protect the whole family’s health.',
        forHome:
            'Routine cleaning keeps furniture and surfaces looking like new for years to come.',
        takeaway:
            'Diligence & Care: Paying attention to small details makes a big difference in our environment.',
      );
    }

    // 12. Universal default
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
