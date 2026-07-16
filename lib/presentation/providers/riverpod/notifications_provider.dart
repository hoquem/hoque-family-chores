import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/repositories/notification_repository.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

part 'notifications_provider.g.dart';

/// Streams the user's notifications, newest first.
///
/// Failures from the underlying stream surface as the provider's error
/// state — never as a silently empty list.
@riverpod
Stream<List<Notification>> notifications(Ref ref, UserId userId) {
  final streamUseCase = ref.watch(streamNotificationsUseCaseProvider);
  return streamUseCase.call(userId: userId).map(
        (result) => result.fold(
          (failure) => throw Exception(failure.message),
          (notifications) {
            final sorted = [...notifications]
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return sorted;
          },
        ),
      );
}
