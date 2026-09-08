import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/chore_guide.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/chore_guide_card.dart';

void main() {
  testWidgets('ChoreGuideCard renders motivation, steps, and reasons correctly',
      (tester) async {
    const guide = ChoreGuide(
      motivation: 'Put on your favorite track and race the timer!',
      steps: [
        'Pull sheets straight',
        'Smooth out duvet',
        'Fluff the pillow',
      ],
      forYou: 'Your room will feel super cozy.',
      forFamily: 'Helps mom and dad relax.',
      forHome: 'Keeps our home looking sharp.',
      takeaway: 'Daily Habit & Focus.',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: appLightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChoreGuideCard(guide: guide),
          ),
        ),
      ),
    );

    // Header
    expect(find.text('Mission Guide & Tips'), findsOneWidget);
    expect(find.text('How to crush it and why it matters'), findsOneWidget);

    // Power boost
    expect(find.text('POWER BOOST'), findsOneWidget);
    expect(find.text(guide.motivation), findsOneWidget);

    // Steps (clean read-only numbered list)
    expect(find.text('STEPS TO COMPLETE'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Pull sheets straight'), findsOneWidget);
    expect(find.text('Smooth out duvet'), findsOneWidget);
    expect(find.text('Fluff the pillow'), findsOneWidget);

    // Why this helps
    expect(find.text('WHY THIS HELPS'), findsOneWidget);
    expect(find.textContaining('Your room will feel super cozy.'), findsOneWidget);
    expect(find.textContaining('Helps mom and dad relax.'), findsOneWidget);
    expect(find.textContaining('Keeps our home looking sharp.'), findsOneWidget);

    // Takeaway superpower
    expect(find.text('SUPERPOWER TAKEAWAY'), findsOneWidget);
    expect(find.text(guide.takeaway), findsOneWidget);
  });

  testWidgets('ChoreGuideCard returns SizedBox.shrink when guide is empty',
      (tester) async {
    const emptyGuide = ChoreGuide(
      motivation: '',
      steps: [],
      forYou: '',
      forFamily: '',
      forHome: '',
      takeaway: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: appLightTheme,
        home: Scaffold(
          body: ChoreGuideCard(guide: emptyGuide),
        ),
      ),
    );

    expect(find.text('Mission Guide & Tips'), findsNothing);
  });

  testWidgets('ChoreGuideCard renders HOME NOTE FROM PARENT and handles onEditParentTip',
      (tester) async {
    bool editTapped = false;
    const guideWithNote = ChoreGuide(
      motivation: 'Get it done!',
      steps: ['Step 1'],
      forYou: 'Good for you',
      forFamily: 'Good for family',
      forHome: 'Good for home',
      takeaway: 'Superpower',
      parentTip: 'Recycling bin is blue behind garage',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: appLightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChoreGuideCard(
              guide: guideWithNote,
              onEditParentTip: () => editTapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('HOME NOTE FROM PARENT'), findsOneWidget);
    expect(find.text('Recycling bin is blue behind garage'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pump();
    expect(editTapped, isTrue);
  });

  testWidgets('ChoreGuideCard strictly obeys the 14px Floor Rule and Ink-Label Rule',
      (tester) async {
    const guide = ChoreGuide(
      motivation: 'Boost your energy and race the clock!',
      steps: ['Step 1: Get started', 'Step 2: Finish strong'],
      forYou: 'Gain focus and confidence.',
      forFamily: 'Brings calm to the household.',
      forHome: 'Clean space to live.',
      takeaway: 'Building lifelong discipline.',
      parentTip: 'Cleaning supplies are in the kitchen cabinet.',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: appLightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChoreGuideCard(
              guide: guide,
              onEditParentTip: () {},
            ),
          ),
        ),
      ),
    );

    // 1. Verify every rendered Text widget has fontSize >= 14
    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    expect(textWidgets, isNotEmpty);
    for (final text in textWidgets) {
      final style = text.style;
      if (style?.fontSize != null) {
        expect(
          style!.fontSize,
          greaterThanOrEqualTo(14.0),
          reason:
              'Text "${text.data}" has fontSize ${style.fontSize}px; violates the 14px Floor Rule',
        );
      }
    }

    // 2. Verify RichText spans (such as _WhyRow) have fontSize >= 14
    final richWidgets = tester.widgetList<RichText>(find.byType(RichText));
    for (final rich in richWidgets) {
      if (rich.text is TextSpan) {
        final span = rich.text as TextSpan;
        if (span.style?.fontSize != null) {
          expect(
            span.style!.fontSize,
            greaterThanOrEqualTo(14.0),
            reason:
                'RichText span has fontSize ${span.style!.fontSize}px; violates the 14px Floor Rule',
          );
        }
      }
    }

    // 3. Verify Ink-Label Rule: POWER BOOST, SUPERPOWER TAKEAWAY, and HOME NOTE FROM PARENT headers are ink
    final homeNoteLabel = tester.widget<Text>(find.text('HOME NOTE FROM PARENT'));
    expect(homeNoteLabel.style?.color, equals(kLightTokens.ink));

    final powerBoostLabel = tester.widget<Text>(find.text('POWER BOOST'));
    expect(powerBoostLabel.style?.color, equals(kLightTokens.ink));

    final superpowerLabel =
        tester.widget<Text>(find.text('SUPERPOWER TAKEAWAY'));
    expect(superpowerLabel.style?.color, equals(kLightTokens.ink));
  });
}
