import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/notification_icon.dart';

void main() {
  group('NotificationIcon', () {
    testWidgets('shows a type-aware icon when there is no image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appLightTheme,
          home: const Scaffold(
            body: NotificationIcon(
              isRead: false,
              type: 'taskApproved',
              imageUrl: null,
            ),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsNothing);
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
    });

    testWidgets('shows a photo avatar when imageUrl is present',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appLightTheme,
          home: const Scaffold(
            body: NotificationIcon(
              isRead: false,
              type: 'taskApproved',
              imageUrl: 'https://example.com/avatar.jpg',
            ),
          ),
        ),
      );

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundImage, isA<NetworkImage>());
    });
  });
}
