import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_notifier.dart';

import '../mocks/mock_family_repository.dart';

User _member() => User(
      id: UserId('uid_1'),
      name: 'Member One',
      email: Email('one@example.com'),
      familyId: FamilyId('fam_1'),
      role: UserRole.parent,
      points: Points(0),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

/// Fails [failures] times before succeeding, recording the attempt count.
class _FlakyFamilyRepository extends MockFamilyRepository {
  _FlakyFamilyRepository({required this.error, required this.failures});

  final ServerException error;
  int failures;
  int attempts = 0;

  @override
  Future<List<User>> getFamilyMembers(FamilyId familyId) async {
    attempts++;
    if (failures > 0) {
      failures--;
      throw error;
    }
    return [_member()];
  }
}

void main() {
  test('permission-denied is retried: the consistency window resolves',
      () async {
    // Firestore latency compensation delivers the profile's new familyId to
    // the app before the server has committed it, so the first members query
    // can be denied by rules even though the data is correct moments later.
    final repo = _FlakyFamilyRepository(
      error: const ServerException(
        'Failed to get family members: [cloud_firestore/permission-denied] '
        'The caller does not have permission',
        code: 'FAMILY_MEMBERS_FETCH_ERROR',
      ),
      failures: 2,
    );
    final container = ProviderContainer(
      overrides: [familyRepositoryProvider.overrideWith((_) => repo)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(
        familyMembersNotifierProvider(FamilyId('fam_1')), (_, __) {});
    addTearDown(sub.close);

    final members = await container
        .read(familyMembersNotifierProvider(FamilyId('fam_1')).future);

    expect(members, hasLength(1));
    expect(repo.attempts, 3, reason: '2 denied attempts, then success');
  });

  test('non-permission errors fail immediately without retry', () async {
    final repo = _FlakyFamilyRepository(
      error: const ServerException('network unreachable', code: 'X'),
      failures: 10,
    );
    final container = ProviderContainer(
      overrides: [familyRepositoryProvider.overrideWith((_) => repo)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(
        familyMembersNotifierProvider(FamilyId('fam_1')), (_, __) {});
    addTearDown(sub.close);

    await expectLater(
      container.read(familyMembersNotifierProvider(FamilyId('fam_1')).future),
      throwsA(isA<Exception>()),
    );
    expect(repo.attempts, 1,
        reason: 'a real failure must surface, not spin in retries');
  });
}
