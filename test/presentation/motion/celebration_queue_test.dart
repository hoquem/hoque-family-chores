import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';

void main() {
  test('celebrations queue in order and advance one at a time', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final queue = container.read(celebrationQueueProvider.notifier);

    queue.celebrate(const StarsAwarded(10));
    queue.celebrate(const StreakMilestone(7));

    List<CelebrationKind> kinds() =>
        container.read(celebrationQueueProvider).map((q) => q.kind).toList();

    expect(kinds(), const [StarsAwarded(10), StreakMilestone(7)]);

    queue.advance();
    expect(kinds(), const [StreakMilestone(7)]);
    queue.advance();
    expect(kinds(), isEmpty);
    queue.advance(); // advancing an empty queue is a no-op, not a crash
    expect(kinds(), isEmpty);
  });

  test('each entry gets a unique sequence number, even for equal kinds', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final queue = container.read(celebrationQueueProvider.notifier);

    queue.celebrate(const StarsAwarded(10));
    queue.celebrate(const StarsAwarded(10)); // identical payoff twice
    final entries = container.read(celebrationQueueProvider);
    expect(entries[0].seq, isNot(entries[1].seq),
        reason: 'the overlay keys off seq — equal kinds must still be '
            'distinct entries or the second show never restarts');
  });

  test('kinds carry their payloads and compare by value', () {
    expect(const StarsAwarded(5), const StarsAwarded(5));
    expect(
        const TreatRedeemed('Movie night'), const TreatRedeemed('Movie night'));
    expect(const StreakMilestone(3), isNot(const StreakMilestone(7)));
  });
}
