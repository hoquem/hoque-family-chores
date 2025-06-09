// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/main.dart';
import 'package:hoque_family_chores/models/enums.dart'; // ADDED: For TaskStatus, TaskDifficulty, etc.
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/services/data_service_factory.dart';
import 'package:hoque_family_chores/services/data_service_interface.dart'; // ADDED: The correct interface
import 'package:hoque_family_chores/services/gamification_service_interface.dart'; // ADDED: The correct interface
import 'package:hoque_family_chores/services/mock_data_service.dart';
import 'package:hoque_family_chores/services/mock_gamification_service.dart'; // ADDED: The mock implementation
import 'package:provider/provider.dart';

void main() {
  late DataServiceInterface dataService;
  late GamificationServiceInterface mockGamificationService;

  // This setup runs before each test, ensuring a clean state.
  setUp(() {
    // Use the factory to get a fresh mock service instance for each test.
    dataService = DataServiceFactory.getDataService(forceMock: true);
    mockGamificationService = MockGamificationService();
  });

  group('Data Service Factory and Mock Service Tests', () {
    test('Data service factory should return MockDataService in test environment', () {
      final service = DataServiceFactory.getDataService();
      expect(service, isA<MockDataService>());
    });

    test('Mock service should allow sign in and sign out', () async {
      // Sign in
      final userId = await dataService.signIn(
        email: 'ahmed@example.com',
        password: 'password123',
      );
      expect(userId, isNotNull);
      expect(await dataService.isAuthenticated(), isTrue);

      // Sign out
      await dataService.signOut();
      expect(await dataService.isAuthenticated(), isFalse);
    });

    test('Mock service should create a new task', () async {
      // Arrange: Sign in and get familyId
      final userId = await dataService.signIn(email: 'ahmed@example.com', password: 'password123');
      final profile = await dataService.getUserProfile(userId: userId!);
      final familyId = profile!['familyId'] as String;

      // Act: Create a task
      final taskId = await dataService.createTask(
        title: 'Test Task',
        description: 'A test task',
        familyId: familyId,
        difficulty: TaskDifficulty.medium, // MODIFIED: Uses the imported enum
      );

      // Assert: Verify the task was created correctly
      final task = await dataService.getTask(taskId: taskId);
      expect(task, isNotNull);
      expect(task!['title'], equals('Test Task'));
      expect(task['status'], equals(TaskStatus.pending.name)); // MODIFIED: Uses the imported enum
    });
  });

  group('Widget and Provider Tests', () {
    testWidgets('App initializes and shows LoginScreen', (WidgetTester tester) async {
      // Build our app with the mock services.
      await tester.pumpWidget(MyApp(
        dataService: dataService,
        gamificationService: mockGamificationService,
      ));

      // Wait for all frames to settle
      await tester.pumpAndSettle();
      
      // Verify that the app shows the login screen for unauthenticated users.
      expect(find.text('Welcome'), findsOneWidget);
    });

    testWidgets('AuthProvider correctly signs in and updates state', (WidgetTester tester) async {
      // Arrange: Build a test app with the necessary providers.
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            // Provide the mock services
            Provider<DataServiceInterface>.value(value: dataService),
            Provider<GamificationServiceInterface>.value(value: mockGamificationService),
            
            // Create the AuthProvider depending on the DataService
            ChangeNotifierProxyProvider<DataServiceInterface, AuthProvider>(
              create: (_) => AuthProvider(),
              update: (_, dataService, authProvider) =>
                  authProvider!..updateDataService(dataService),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Text('TestWidgetForAuthProvider'),
            ),
          ),
        ),
      );

      // Act: Get the AuthProvider and call signIn
      final context = tester.element(find.text('TestWidgetForAuthProvider'));
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final bool success = await authProvider.signIn(
        email: 'ahmed@example.com',
        password: 'password123',
      );

      // Assert: Check if the provider's state updated correctly
      expect(success, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      // MODIFIED: Uses the correct getter from the definitive AuthProvider
      expect(authProvider.currentUserId, isNotNull); 
      expect(authProvider.displayName, equals('Ahmed Hoque'));
    });
  });
}