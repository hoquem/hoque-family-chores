// The Family tab's invite entry point used to be a bare, unlabelled icon.
// This pins the labelled "Invite someone" button that shares directly, in
// one tap, alongside the icon (kept so Copy stays reachable via the dialog).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/data/services/invite_sharer.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/services/invite_message.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/family_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';
const _code = 'ABCDEFGHJKMN';
final _familyId = FamilyId('fam_1');

class _FamilyWithCode extends MockFamilyRepository {
  @override
  Future<FamilyEntity?> getFamily(FamilyId familyId) async => FamilyEntity(
        id: _familyId,
        name: 'Test Family',
        description: '',
        creatorId: UserId(_uid),
        memberIds: [UserId(_uid)],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        inviteCode: _code,
      );
}

class _FakeSharer implements InviteSharer {
  final shared = <String>[];

  @override
  Future<bool> share(String text, {Rect? origin}) async {
    shared.add(text);
    return true;
  }
}

void main() {
  testWidgets(
      'the labelled Invite someone button on the Family tab shares directly',
      (tester) async {
    final sharer = _FakeSharer();
    final firestore = FakeFirebaseFirestore();
    final users = MockUserRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
        userRepositoryProvider.overrideWith((_) => users),
        familyRepositoryProvider.overrideWith((_) => _FamilyWithCode()),
        inviteSharerProvider.overrideWith((_) => sharer),
        analyticsProvider.overrideWith((_) => Analytics(firestore)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: appLightTheme, home: const FamilyScreen()),
      ),
    );
    await tester.runAsync(() async {
      await container.read(authNotifierProvider.notifier).signInWithGoogle();
      final profile = await users.getUserProfile(UserId(_uid));
      await users.updateUserProfile(profile!.copyWith(familyId: _familyId));
    });
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Both entry points exist: the labelled button and the original icon.
    expect(find.text('Invite someone'), findsOneWidget);
    expect(find.byTooltip('Invite someone'), findsOneWidget);

    await tester.tap(find.text('Invite someone'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(sharer.shared, [inviteMessage(_code)]);
    expect(find.byType(AlertDialog), findsNothing,
        reason: 'the labelled button shares directly, no dialog');

    final events =
        await tester.runAsync(() => firestore.collection('analyticsEvents').get());
    final docs = events!.docs.where((d) => d['name'] == 'inviteShared');
    expect(docs, hasLength(1));
    expect(docs.first['params']['source'], 'family_tab');
  });
}
