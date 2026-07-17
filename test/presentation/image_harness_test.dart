// Proves the image harness works, so the before/after pair can be tested.
//
// No remote image had ever rendered in this suite. Flutter's test HttpClient
// returns 400 for every request, so a network image throws — and nobody hit it
// because every fixture set photoUrl: null. The before/after pair puts two
// remote images at the centre of the approval screen, so this had to be solved
// before those tests could exist.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';

void main() {
  testWidgets('a remote image renders inside the harness', (tester) async {
    await mockNetworkImages(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CachedNetworkImage(
              imageUrl: 'https://example.com/before.jpg',
              placeholder: (_, __) => const CircularProgressIndicator(),
              errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
            ),
          ),
        ),
      );
      // pump(), not pumpAndSettle(): the placeholder is a
      // CircularProgressIndicator, which animates forever, so pumpAndSettle
      // never returns. Two pumps is enough for the image to resolve.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      // The error widget appearing would mean the harness is not intercepting.
      expect(find.byIcon(Icons.broken_image), findsNothing);
    });
  });

}
