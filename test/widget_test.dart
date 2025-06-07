// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/services/gamification_service.dart';
import 'package:hoque_family_chores/main.dart';

void main() {
  testWidgets('App startup smoke test', (WidgetTester tester) async {
    // Create a mock gamification service
    final mockGamificationService = MockGamificationService();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(gamificationService: mockGamificationService));

    // Verify that the login screen appears with key unique elements
    expect(find.text('Welcome!'), findsOneWidget);
    
    // Check for text fields
    expect(find.byType(TextField), findsAtLeast(2)); // Email and password fields
    expect(find.text('Email'), findsOneWidget); // Email label
    expect(find.text('Password'), findsOneWidget); // Password label
    
    // Check for buttons - avoid checking specific text that might be duplicated
    expect(find.byType(ElevatedButton), findsAtLeast(1));
    
    // Check for registration link - this is unique
    expect(find.text("Don't have an account? Register here"), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
    
    // Check for app structure elements
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    
    // The test passing means the app started without crashing
    // and displays the expected login screen elements
  });
}
