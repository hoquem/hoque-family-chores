import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/motion/streak_milestone_watcher.dart';

void main() {
  test('first report is baseline — no celebration', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(streakMilestoneWatcherProvider.notifier).report(7);
    await Future.delayed(Duration.zero);
    expect(container.read(celebrationQueueProvider), isEmpty);
  });

  test('crossing into a milestone celebrates once', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(streakMilestoneWatcherProvider.notifier);
    notifier.report(2);
    notifier.report(3);
    await Future.delayed(Duration.zero);

    final kinds = container.read(celebrationQueueProvider).map((q) => q.kind);
    expect(kinds, [const StreakMilestone(3)]);
  });

  test('non-milestone streak does not celebrate', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(streakMilestoneWatcherProvider.notifier);
    notifier.report(3);
    notifier.report(4);
    await Future.delayed(Duration.zero);

    expect(container.read(celebrationQueueProvider), isEmpty);
  });

  test('milestone reported again after rebuild does not duplicate', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(streakMilestoneWatcherProvider.notifier);
    notifier.report(6);
    notifier.report(7);
    notifier.report(7);
    await Future.delayed(Duration.zero);

    expect(container.read(celebrationQueueProvider).length, 1);
  });

  test('streak broken then rebuilt celebrates again', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(streakMilestoneWatcherProvider.notifier);
    notifier.report(7);
    notifier.report(0);
    notifier.report(3);
    await Future.delayed(Duration.zero);

    final kinds = container.read(celebrationQueueProvider).map((q) => q.kind);
    expect(kinds, [const StreakMilestone(3)]);
  });

  testWidgets('report from inside build does not throw', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Baseline established outside build.
    container.read(streakMilestoneWatcherProvider.notifier).report(2);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            // Crossing into milestone from inside build — must not throw.
            ref.read(streakMilestoneWatcherProvider.notifier).report(3);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.runAsync(() => Future.delayed(Duration.zero));

    // No "modify provider during build" exception was thrown.
    final kinds = container.read(celebrationQueueProvider).map((q) => q.kind);
    expect(kinds, [const StreakMilestone(3)]);
  });
}
