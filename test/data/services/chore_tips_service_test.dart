import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/services/chore_tips_service.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<dynamic> {}

void main() {
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late ChoreTipsService service;

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    when(() => mockFunctions.httpsCallable(any(), options: any(named: 'options')))
        .thenReturn(mockCallable);
    service = ChoreTipsService(functions: mockFunctions);
  });

  group('ChoreTipsService Heuristic Fallbacks (Offline & Instant)', () {
    test('returns bathroom tips when title contains bathroom or bath', () async {
      // Offline / no cloud function response
      when(() => mockCallable.call(any()))
          .thenThrow(Exception('Network unavailable'));

      final guide = await service.generateChoreGuide(
        title: 'Clean the middle bathroom',
        difficulty: TaskDifficulty.medium,
      );

      expect(guide.isNotEmpty, isTrue);
      expect(guide.motivation, contains('Sparkle mission'));
      expect(guide.steps.any((s) => s.contains('towels') || s.contains('bath mats')), isTrue);
      expect(guide.steps.any((s) => s.contains('sink') || s.contains('faucets')), isTrue);
      expect(guide.steps.any((s) => s.contains('toilet')), isTrue);
      expect(guide.takeaway, contains('Hygiene & Sanitation'));
    });

    test('returns bed tips when title contains bed', () async {
      when(() => mockCallable.call(any()))
          .thenThrow(Exception('Network unavailable'));

      final guide = await service.generateChoreGuide(
        title: 'Make your bed',
        difficulty: TaskDifficulty.easy,
      );

      expect(guide.isNotEmpty, isTrue);
      expect(guide.motivation, contains('Start your day'));
      expect(guide.steps.length, greaterThanOrEqualTo(3));
      expect(guide.forYou, contains('cozy'));
      expect(guide.takeaway, contains('Habit'));
    });

    test('returns dishes tips when title contains dish or kitchen', () async {
      when(() => mockCallable.call(any()))
          .thenThrow(Exception('Network unavailable'));

      final guide = await service.generateChoreGuide(
        title: 'Wash the dishes',
        difficulty: TaskDifficulty.medium,
      );

      expect(guide.isNotEmpty, isTrue);
      expect(guide.motivation, contains('favorite 3-minute song'));
      expect(guide.steps, contains('Scrape leftover food into the food bin'));
      expect(guide.forYou, contains('kitchen independence'));
      expect(guide.takeaway, contains('Teamwork'));
    });

    test('returns trash tips when title contains trash or bin', () async {
      when(() => mockCallable.call(any()))
          .thenThrow(Exception('Network unavailable'));

      final guide = await service.generateChoreGuide(
        title: 'Take out the kitchen trash',
        difficulty: TaskDifficulty.easy,
      );

      expect(guide.isNotEmpty, isTrue);
      expect(guide.steps, contains('Tie up the bin bag securely so nothing spills out'));
      expect(guide.takeaway, contains('Reliability'));
    });

    test('returns vacuum/floor tips when title contains vacuum or mop', () async {
      when(() => mockCallable.call(any()))
          .thenThrow(Exception('Network unavailable'));

      final guide = await service.generateChoreGuide(
        title: 'Vacuum the stairs and hallway',
        difficulty: TaskDifficulty.medium,
      );

      expect(guide.isNotEmpty, isTrue);
      expect(guide.motivation, contains('Time to pave the runway'));
      expect(guide.takeaway, contains('Thoroughness'));
    });

    test('returns plant tips when title contains water or plant', () async {
      when(() => mockCallable.call(any()))
          .thenThrow(Exception('Network unavailable'));

      final guide = await service.generateChoreGuide(
        title: 'Water the plants',
        difficulty: TaskDifficulty.easy,
      );

      expect(guide.isNotEmpty, isTrue);
      expect(guide.motivation, contains('house plant guardian'));
      expect(guide.takeaway, contains('Nurturing'));
    });

    test('returns tidy tips for tidy / organize without assuming a bed', () async {
      when(() => mockCallable.call(any()))
          .thenThrow(Exception('Network unavailable'));

      final guide = await service.generateChoreGuide(
        title: 'Tidy the playroom',
        difficulty: TaskDifficulty.easy,
      );

      expect(guide.isNotEmpty, isTrue);
      expect(guide.motivation, contains('Zone blitz'));
      expect(guide.steps.any((s) => s.contains('boxes, shelves')), isTrue);
      expect(guide.takeaway, contains('Spatial Organization'));
    });

    test('returns generic tips for unknown custom chore when offline', () async {
      when(() => mockCallable.call(any()))
          .thenThrow(Exception('Network unavailable'));

      final guide = await service.generateChoreGuide(
        title: 'Fix bicycle chain',
        difficulty: TaskDifficulty.hard,
      );

      expect(guide.isNotEmpty, isTrue);
      expect(guide.motivation, contains('stars'));
      expect(guide.steps.length, 3);
      expect(guide.forYou, isNotEmpty);
      expect(guide.takeaway, contains('Diligence'));
    });
  });

  group('ChoreTipsService Cloud Function Integration', () {
    test('successfully parses Cloud Function response', () async {
      final mockResult = MockHttpsCallableResult();
      when(() => mockResult.data).thenReturn({
        'motivation': 'Hype time! Show those clothes who is boss!',
        'steps': [
          'Check all pockets for toys or coins',
          'Fold trousers along the seams',
          'Stack folded items neatly in drawers',
        ],
        'forYou': 'Your wardrobe will look like a neat boutique.',
        'forFamily': 'Helps the whole family stay organized.',
        'forHome': 'Keeps bedroom chairs clutter-free.',
        'takeaway': 'Orderliness & Independence: Small habits build a big future.',
      });

      when(() => mockCallable.call(any())).thenAnswer((_) async => mockResult);

      final guide = await service.generateChoreGuide(
        title: 'Fold laundry',
        difficulty: TaskDifficulty.medium,
      );

      expect(guide.motivation, 'Hype time! Show those clothes who is boss!');
      expect(guide.steps.length, 3);
      expect(guide.steps[0], 'Check all pockets for toys or coins');
      expect(guide.forYou, contains('wardrobe'));
      expect(guide.forFamily, contains('family'));
      expect(guide.forHome, contains('chairs'));
      expect(guide.takeaway, contains('Orderliness'));
    });

    test('gracefully falls back when Cloud Function throws error', () async {
      when(() => mockCallable.call(any()))
          .thenThrow(FirebaseFunctionsException(
        message: 'Internal error',
        code: 'internal',
      ));

      final guide = await service.generateChoreGuide(
        title: 'Clean the kitchen dishes',
        difficulty: TaskDifficulty.medium,
      );

      // Should not throw, should fall back to dishes fallback!
      expect(guide.isNotEmpty, isTrue);
      expect(guide.steps, contains('Scrape leftover food into the food bin'));
    });

    test('caches responses and returns cached guide on subsequent calls', () async {
      when(() => mockCallable.call(any()))
          .thenThrow(Exception('Network down'));

      final guide1 = await service.generateChoreGuide(
        title: 'Make your bed',
        difficulty: TaskDifficulty.easy,
        parentTip: 'Fluff pillows twice',
      );

      expect(guide1.parentTip, 'Fluff pillows twice');
      expect(service.getCachedGuide(
        title: 'Make your bed',
        difficulty: TaskDifficulty.easy,
        parentTip: 'Fluff pillows twice',
      ), equals(guide1));

      // Instant fallback also attaches parentTip
      final instantFallback = service.getInstantFallbackGuide(
        title: 'Clean the middle bathroom',
        parentTip: 'Use the green spray under the sink',
      );
      expect(instantFallback.parentTip, 'Use the green spray under the sink');
      expect(instantFallback.steps.any((s) => s.contains('toilet')), isTrue);
    });
  });
}
