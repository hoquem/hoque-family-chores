import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/data/services/invite_sharer.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/home/invite_family_card.dart';

class _FakeSharer implements InviteSharer {
  final shared = <String>[];

  @override
  Future<void> share(String text, {Rect? origin}) async {
    shared.add(text);
  }
}

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

User _adult() => User(
      id: UserId('adult_uid'),
      name: 'Ada',
      email: Email('ada@example.com'),
      familyId: FamilyId('fam_1'),
      role: UserRole.parent,
      points: Points(0),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required VoidCallback onDismiss,
    required InviteSharer sharer,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider
              .overrideWith(() => _FixedAuthNotifier(AuthState(user: _adult()))),
          inviteSharerProvider.overrideWith((_) => sharer),
          analyticsProvider.overrideWith((_) => Analytics(FakeFirebaseFirestore())),
        ],
        child: MaterialApp(
          theme: appLightTheme,
          home: Scaffold(
            body: InviteFamilyCard(
              inviteCode: 'ABCDEFGHJKMN',
              onDismiss: onDismiss,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the why line and a Share invite button', (tester) async {
    await pump(tester, onDismiss: () {}, sharer: _FakeSharer());

    expect(find.text('Invite your family'), findsOneWidget);
    expect(
      find.textContaining('Chores Star works best with everyone in'),
      findsOneWidget,
    );
    expect(find.text('Share invite'), findsOneWidget);
  });

  testWidgets('the dismiss button calls onDismiss', (tester) async {
    var dismissed = false;
    await pump(tester, onDismiss: () => dismissed = true, sharer: _FakeSharer());

    await tester.tap(find.byKey(const Key('invite_family_card_dismiss')));
    await tester.pump();

    expect(dismissed, isTrue);
  });

  testWidgets('Share invite shares with source home_card', (tester) async {
    final sharer = _FakeSharer();
    final firestore = FakeFirebaseFirestore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider
              .overrideWith(() => _FixedAuthNotifier(AuthState(user: _adult()))),
          inviteSharerProvider.overrideWith((_) => sharer),
          analyticsProvider.overrideWith((_) => Analytics(firestore)),
        ],
        child: MaterialApp(
          theme: appLightTheme,
          home: Scaffold(
            body: InviteFamilyCard(
              inviteCode: 'ABCDEFGHJKMN',
              onDismiss: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Share invite'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(sharer.shared, hasLength(1));
    final events =
        await tester.runAsync(() => firestore.collection('analyticsEvents').get());
    final docs = events!.docs.where((d) => d['name'] == 'inviteShared');
    expect(docs, hasLength(1));
    expect(docs.first['params']['source'], 'home_card');
  });
}
