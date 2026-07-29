import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/motion/celebration_listener.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../../mocks/mock_auth_repository.dart';

void main() {
  testWidgets('two queued celebrations play sequentially, never stacked',
      (tester) async {
    // The auth repository is mocked because Task 7 activates the star-award
    // watcher inside CelebrationListener — without this override the real
    // AuthNotifier.build would touch FirebaseAuth and crash the test.
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: appLightTheme,
          home: const Scaffold(
            body: CelebrationListener(child: SizedBox.expand()),
          ),
        ),
      ),
    );

    container.read(celebrationQueueProvider.notifier)
      ..celebrate(const StarsAwarded(10))
      ..celebrate(const StreakMilestone(3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // First plays alone.
    expect(find.textContaining('+10'), findsOneWidget);
    expect(find.textContaining('streak'), findsNothing);

    // After the first envelope, the second plays.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('+10'), findsNothing);
    expect(find.textContaining('3-day streak'), findsOneWidget);

    // Then silence.
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.textContaining('streak'), findsNothing);
    expect(container.read(celebrationQueueProvider), isEmpty);
  });
}
