import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/riverpod_container.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/value_objects/user_id.dart';

/// One member's live profile. Hand-written (build_runner is broken).
///
/// Screens that list or show family members watch this so stars and the
/// managed/linked state follow the server instead of a one-shot snapshot.
final memberProfileProvider =
    StreamProvider.autoDispose.family<User?, UserId>((ref, id) {
  return ref.watch(userRepositoryProvider).streamUserProfile(id);
});
