import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/member_profile_provider.dart';
import 'package:hoque_family_chores/presentation/screens/family_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';
final _familyId = FamilyId('fam_1');

User _kid({required int points, required bool managed}) => User(
      id: UserId('kid'),
      name: 'Amira',
      familyId: _familyId,
      role: UserRole.child,
      points: Points(points),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isManaged: managed,
    );

/// Serves a one-shot member list holding the child as loaded at startup.
class _SnapshotFamilyRepository extends MockFamilyRepository {
  @override
  Future<FamilyEntity?> getFamily(FamilyId familyId) async => FamilyEntity(
        id: _familyId,
        name: 'Test Family',
        description: '',
        creatorId: UserId(_uid),
        memberIds: [UserId(_uid)],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        inviteCode: 'ABC234',
      );

  @override
  Future<List<User>> getFamilyMembers(FamilyId familyId) async =>
      [_kid(points: 0, managed: true)];
}

void main() {
  testWidgets('a member row follows the live profile, not the loaded snapshot',
      (tester) async {
    final live = StreamController<User?>();
    addTearDown(live.close);
    final users = MockUserRepository();
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => users),
      familyRepositoryProvider.overrideWith((_) => _SnapshotFamilyRepository()),
      memberProfileProvider(UserId('kid')).overrideWith((_) => live.stream),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: appLightTheme, home: const FamilyScreen()),
    ));
    await tester.runAsync(() async {
      await container.read(authNotifierProvider.notifier).signInWithGoogle();
      final profile = await users.getUserProfile(UserId(_uid));
      await users.updateUserProfile(profile!.copyWith(familyId: _familyId));
    });
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // While the live stream has not emitted, the snapshot is shown.
    expect(find.text('Child · No phone'), findsOneWidget);
    expect(find.text('0 ⭐'), findsOneWidget);

    live.add(_kid(points: 5, managed: true));
    await tester.pumpAndSettle();
    expect(find.text('5 ⭐'), findsOneWidget);
    expect(find.text('Child · No phone'), findsOneWidget);

    live.add(_kid(points: 5, managed: false));
    await tester.pumpAndSettle();
    expect(find.text('Child'), findsOneWidget);
    expect(find.textContaining('No phone'), findsNothing);
  });
}
