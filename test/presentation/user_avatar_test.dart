// The avatar resolves by precedence: chosen emoji → photo → name initial.
// The emoji branch is the new one (TASK-455); the initial fallback must survive.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/widgets/user_avatar.dart';

User _user({String? emoji, String? photoUrl, String name = 'Ada'}) => User(
      id: UserId('u1'),
      name: name,
      photoUrl: photoUrl,
      avatarEmoji: emoji,
      familyId: FamilyId('fam1'),
      role: UserRole.child,
      points: Points(0),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Future<void> _pump(WidgetTester tester, User user) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: UserAvatar(user: user))),
    );

void main() {
  testWidgets('shows the chosen emoji when set', (tester) async {
    await _pump(tester, _user(emoji: '🦊', photoUrl: 'https://x/p.jpg'));
    expect(find.text('🦊'), findsOneWidget);
    expect(find.text('A'), findsNothing);
  });

  testWidgets('falls back to the name initial when no emoji and no photo',
      (tester) async {
    await _pump(tester, _user(name: 'Ada'));
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('empty emoji is treated as unset (shows the initial)',
      (tester) async {
    await _pump(tester, _user(emoji: '', name: 'Bo'));
    expect(find.text('B'), findsOneWidget);
  });
}
