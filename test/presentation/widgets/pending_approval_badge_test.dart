import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/presentation/widgets/pending_approval_badge.dart';

void main() {
  testWidgets('reduced motion: static badge without scale animation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: PendingApprovalBadge(
              familyId: FamilyId('fam1'),
              animate: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // No ScaleTransition under reduced motion.
    expect(find.byType(ScaleTransition), findsNothing);
  });
}
