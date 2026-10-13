// The chore-done tick plays only once the write has succeeded, so a failed
// mark-done never sounds like a success.
import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/sound/app_sound.dart';
import 'package:hoque_family_chores/presentation/sound/sound_player.dart';
import 'package:hoque_family_chores/presentation/sound/sound_service.dart';

import '../../mocks/mock_task_repository.dart';
import 'fake_sound_player.dart';

final _familyId = FamilyId('family_1');
// Seeded by MockTaskRepository: 'Do laundry', assigned to user_2.
const _taskId = 'task_2';

/// A player whose sound never finishes, as a slow audio device would behave.
class _HangingSoundPlayer implements SoundPlayer {
  @override
  Future<void> play(String asset) => Completer<void>().future;
}

(ProviderContainer, T) _setUp<T extends SoundPlayer>(T player) {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer(overrides: [
    taskRepositoryProvider.overrideWith((_) => MockTaskRepository()),
    analyticsProvider.overrideWith((_) => Analytics(FakeFirebaseFirestore())),
    soundPlayerProvider.overrideWithValue(player),
  ]);
  addTearDown(container.dispose);
  return (container, player);
}

void main() {
  test('a successful mark-done plays the tick once', () async {
    final (container, player) = _setUp(FakeSoundPlayer());
    await container
        .read(taskListNotifierProvider(_familyId).notifier)
        .completeTask(_taskId, UserId('user_2'), _familyId);
    expect(player.played, [AppSound.choreDone.asset]);
  });

  test('a failed mark-done plays nothing', () async {
    final (container, player) = _setUp(FakeSoundPlayer());
    // Only the assignee may complete it, so this one is refused.
    await expectLater(
      container
          .read(taskListNotifierProvider(_familyId).notifier)
          .completeTask(_taskId, UserId('user_9'), _familyId),
      throwsException,
    );
    expect(player.played, isEmpty);
  });

  test('mark-done does not wait for the tick to finish', () async {
    final (container, _) = _setUp(_HangingSoundPlayer());
    await container
        .read(taskListNotifierProvider(_familyId).notifier)
        .completeTask(_taskId, UserId('user_2'), _familyId)
        .timeout(const Duration(seconds: 5));
  });
}
