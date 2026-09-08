import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/environment_service.dart';
import 'package:hoque_family_chores/data/services/chore_tips_service.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockEnvironmentService extends Mock implements EnvironmentService {}

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockEnvironmentService mockEnv;
  late MockHttpClient mockHttp;
  late ChoreTipsService service;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockEnv = MockEnvironmentService();
    mockHttp = MockHttpClient();
    service = ChoreTipsService(
      environmentService: mockEnv,
      httpClient: mockHttp,
    );
  });

  group('ChoreTipsService Fallback', () {
    test('returns bed tips when title contains bed', () async {
      when(() => mockEnv.hasGeminiApiKey).thenReturn(false);

      final guide = await service.generateChoreGuide(
        title: 'Make your bed',
        difficulty: TaskDifficulty.easy,
      );

      expect(guide.isNotEmpty, isTrue);
      expect(guide.motivation, contains('Start your day'));
      expect(guide.steps.length, greaterThanOrEqualTo(3));
      expect(guide.forYou, contains('cozy'));
      expect(guide.forFamily, isNotEmpty);
      expect(guide.forHome, isNotEmpty);
      expect(guide.takeaway, contains('Habit'));
    });

    test('returns dishes tips when title contains dish', () async {
      when(() => mockEnv.hasGeminiApiKey).thenReturn(false);

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

    test('returns trash tips when title contains trash', () async {
      when(() => mockEnv.hasGeminiApiKey).thenReturn(false);

      final guide = await service.generateChoreGuide(
        title: 'Take out the kitchen trash',
        difficulty: TaskDifficulty.easy,
      );

      expect(guide.isNotEmpty, isTrue);
      expect(guide.steps, contains('Tie up the bin bag securely so nothing spills out'));
      expect(guide.takeaway, contains('Reliability'));
    });

    test('returns generic tips for unknown custom chore when offline', () async {
      when(() => mockEnv.hasGeminiApiKey).thenReturn(false);

      final guide = await service.generateChoreGuide(
        title: 'Fix bicycle chain',
        difficulty: TaskDifficulty.hard,
      );

      expect(guide.isNotEmpty, isTrue);
      expect(guide.motivation, contains('stars'));
      expect(guide.steps.length, 3);
      expect(guide.forYou, isNotEmpty);
      expect(guide.forFamily, isNotEmpty);
      expect(guide.forHome, isNotEmpty);
      expect(guide.takeaway, contains('Diligence'));
    });
  });

  group('ChoreTipsService Gemini API', () {
    test('successfully parses structured JSON from Gemini API', () async {
      when(() => mockEnv.hasGeminiApiKey).thenReturn(true);
      when(() => mockEnv.geminiApiKey).thenReturn('test-key');

      final geminiResponsePayload = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
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
                  })
                }
              ]
            }
          }
        ]
      };

      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
        (_) async => http.Response(jsonEncode(geminiResponsePayload), 200),
      );

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

    test('gracefully falls back when Gemini API returns 500 or error', () async {
      when(() => mockEnv.hasGeminiApiKey).thenReturn(true);
      when(() => mockEnv.geminiApiKey).thenReturn('test-key');

      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
        (_) async => http.Response('Server Error', 500),
      );

      final guide = await service.generateChoreGuide(
        title: 'Clean the kitchen dishes',
        difficulty: TaskDifficulty.medium,
      );

      // Should not throw, should fall back to dishes fallback!
      expect(guide.isNotEmpty, isTrue);
      expect(guide.steps, contains('Scrape leftover food into the food bin'));
    });

    test('caches responses and returns cached guide on subsequent calls', () async {
      when(() => mockEnv.hasGeminiApiKey).thenReturn(false);

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
        title: 'Clean room',
        parentTip: 'Put toys in blue bin',
      );
      expect(instantFallback.parentTip, 'Put toys in blue bin');
    });
  });
}
