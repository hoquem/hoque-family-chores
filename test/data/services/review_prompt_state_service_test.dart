// ReviewPromptStateService owns the SharedPreferences keys behind the
// review-prompt gate. Its most important property isn't what it writes —
// it's what it refuses to overwrite: ensureFirstSeenSeeded must be a true
// no-op after the first call, or a returning user's 3-day clock would reset
// on every launch and a daily user would never clear the gate.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/services/review_prompt_state_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ReviewPromptStateService service;

  setUp(() {
    service = ReviewPromptStateService();
  });

  group('ensureFirstSeenSeeded', () {
    test('seeds firstSeenAt on the first call for a fresh install', () async {
      SharedPreferences.setMockInitialValues({});

      await service.ensureFirstSeenSeeded();

      final history = await service.load();
      expect(history.firstSeenAt, isNotNull);
    });

    test(
      'does not overwrite an already-seeded firstSeenAt on a later call',
      () async {
        final originalMillis = DateTime(2026, 1, 1).millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'review_prompt_first_seen_at': originalMillis,
        });

        // A later launch calling this again (main.dart does, every startup)
        // must leave the original date exactly alone.
        await service.ensureFirstSeenSeeded();

        final history = await service.load();
        expect(
          history.firstSeenAt,
          DateTime.fromMillisecondsSinceEpoch(originalMillis),
        );
      },
    );
  });

  group('recordPositiveMoment', () {
    test('increments the count from whatever was already stored', () async {
      SharedPreferences.setMockInitialValues({
        'review_prompt_positive_moment_count': 2,
      });

      final history = await service.recordPositiveMoment();

      expect(history.positiveMomentCount, 3);
      expect((await service.load()).positiveMomentCount, 3);
    });
  });

  group('recordAsked', () {
    test('increments timesAsked and stamps lastAskedAt', () async {
      SharedPreferences.setMockInitialValues({'review_prompt_times_asked': 1});
      final askedAt = DateTime(2026, 4, 1);

      await service.recordAsked(askedAt);

      final history = await service.load();
      expect(history.timesAsked, 2);
      expect(history.lastAskedAt, askedAt);
    });
  });
}
