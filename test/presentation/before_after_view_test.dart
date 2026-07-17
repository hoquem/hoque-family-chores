// The parent-facing half of the feature, at the width a parent actually holds.
//
// Needs the image harness (Task 11): Flutter's test HttpClient 400s every
// request, so without mockNetworkImages both photos would render as errors and
// these assertions would be meaningless.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/before_after_view.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';

const _iphoneSe = Size(320, 568);

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = _iphoneSe;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: appLightTheme,
      home: const Scaffold(
        body: BeforeAfterView(
          beforeUrl: 'https://example.com/before.jpg',
          afterUrl: 'https://example.com/after.jpg',
        ),
      ),
    ),
  );
  // pump(), not pumpAndSettle(): the placeholder spinner never settles.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('opens on the after — the photo being judged', (tester) async {
    await mockNetworkImages(() async {
      await _pump(tester);
      expect(find.text('After'), findsOneWidget);
      expect(find.text('Before'), findsNothing);
    });
  });

  testWidgets('tapping swaps to the before', (tester) async {
    await mockNetworkImages(() async {
      await _pump(tester);

      await tester.tap(find.byType(BeforeAfterView));
      await tester.pump();

      expect(find.text('Before'), findsOneWidget);
      expect(find.text('After'), findsNothing);
    });
  });

  testWidgets('tapping again swaps back', (tester) async {
    await mockNetworkImages(() async {
      await _pump(tester);
      await tester.tap(find.byType(BeforeAfterView));
      await tester.pump();
      await tester.tap(find.byType(BeforeAfterView));
      await tester.pump();
      expect(find.text('After'), findsOneWidget);
    });
  });

  testWidgets('nothing overflows at 320pt', (tester) async {
    await mockNetworkImages(() async {
      await _pump(tester);
      expect(tester.takeException(), isNull,
          reason: 'two photos in a narrow column is exactly where this would '
              'overflow, and the suite only recently started rendering at '
              'phone width');
    });
  });

  testWidgets('a screen reader is told which photo is showing', (tester) async {
    await mockNetworkImages(() async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      // The swap is visual; without this it is silent to a screen reader.
      expect(find.bySemanticsLabel(RegExp('After')), findsOneWidget);

      await tester.tap(find.byType(BeforeAfterView));
      await tester.pump();
      expect(find.bySemanticsLabel(RegExp('Before')), findsOneWidget);

      handle.dispose();
    });
  });
}
