// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart'; // Kept from HEAD

// Added from origin/main, and needed for MyApp constructor
import 'package:hoque_family_chores/services/gamification_service.dart'; 

import 'package:hoque_family_chores/main.dart';
import 'package:hoque_family_chores/services/environment_service.dart';
import 'package:hoque_family_chores/services/data_service.dart';
import 'package:hoque_family_chores/services/data_service_factory.dart';
import 'package:hoque_family_chores/services/mock_data_service.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';

void main() {
  late DataService dataService;
  late EnvironmentService environmentService;
  late GamificationServiceInterface mockGamificationService; // Added for MyApp

  setUp(() {
    // Initialize services before each test
    environmentService = EnvironmentService();
    dataService = DataServiceFactory.getDataService();
    mockGamificationService = MockGamificationService(); // Initialize mock gamification service
  });

  tearDown(() {
    // Clean up after each test
    if (dataService is MockDataService) {
      // Sign out to reset state between tests
      (dataService as MockDataService).signOut(); // Explicit cast for clarity
    }
  });

  group('Environment Service Tests', () {
    test('Environment service should identify test environment', () {
      expect(environmentService.isTestEnvironment, isTrue);
    });

    test('Environment service should use mock data in tests', () {
      expect(environmentService.useMockData, isTrue);
    });

    test('Environment service should not connect to Firebase in tests', () {
      expect(environmentService.shouldConnectToFirebase, isFalse);
    });
  });

  group('Data Service Factory Tests', () {
    test('Data service factory should return MockDataService in test environment', () {
      final service = DataServiceFactory.getDataService();
      expect(service, isA<MockDataService>());
    });

    test('Data service factory explicit mock override works', () {
      final service = DataServiceFactory.getDataService(forceMock: true);
      expect(service, isA<MockDataService>());
    });

    test('Data service factory getMockDataService returns MockDataService', () {
      final service = DataServiceFactory.getMockDataService();
      expect(service, isA<MockDataService>());
    });
  });

  group('Mock Data Service Authentication Tests', () {
    test('Mock service should allow sign in with test credentials', () async {
      // Use one of the predefined test accounts from MockData
      final userId = await dataService.signIn(
        email: 'ahmed@example.com',
        password: 'password123',
      );
      
      expect(userId, isNotNull);
      expect(await dataService.isAuthenticated(), isTrue); 
      expect(dataService.getCurrentUserId(), isNotNull);
    });

    test('Mock service should reject invalid credentials', () async {
      expect(
        () => dataService.signIn(
          email: 'invalid@example.com',
          password: 'wrongpassword',
        ),
        throwsException,
      );
    });

    test('Mock service should allow sign up with new credentials', () async {
      final userId = await dataService.signUp(
        email: 'newuser@example.com',
        password: 'newpassword123',
        displayName: 'New Test User',
      );
      
      expect(userId, isNotNull);
      
      final profile = await dataService.getUserProfile(userId: userId!);
      expect(profile, isNotNull);
      expect(profile!['displayName'], equals('New Test User'));
      expect(profile['email'], equals('newuser@example.com'));
    });

    test('Mock service should allow sign out', () async {
      // First sign in
      await dataService.signIn(
        email: 'ahmed@example.com',
        password: 'password123',
      );
      
      expect(await dataService.isAuthenticated(), isTrue); 
      
      // Then sign out
      await dataService.signOut();
      expect(await dataService.isAuthenticated(), isFalse); 
      expect(dataService.getCurrentUserId(), isNull);
    });
  });

  group('Mock Data Service Task Management Tests', () {
    late String userId;
    late String familyId;
    
    setUp(() async {
      // Sign in before each test in this group
      // Ensure signIn is successful and userId is not null
      final signedInUserId = await dataService.signIn(
        email: 'ahmed@example.com',
        password: 'password123',
      );
      expect(signedInUserId, isNotNull, reason: "Sign-in must succeed for task tests setup");
      userId = signedInUserId!;
      
      // Get family ID from user profile
      final userProfile = await dataService.getUserProfile(userId: userId);
      expect(userProfile, isNotNull, reason: "User profile must exist for task tests setup");
      expect(userProfile!['familyId'], isNotNull, reason: "Family ID must exist in profile for task tests setup");
      familyId = userProfile['familyId'] as String;
    });

    test('Mock service should return tasks for a family', () async {
      final tasks = await dataService.getTasksByFamily(familyId: familyId);
      
      expect(tasks, isNotEmpty);
      expect(tasks.first['familyId'], equals(familyId));
      
      // Check that task has all required fields
      final task = tasks.first;
      expect(task['id'], isNotNull);
      expect(task['title'], isNotNull);
      expect(task['description'], isNotNull);
      expect(task['status'], isNotNull);
    });

    test('Mock service should create a new task', () async {
      final taskId = await dataService.createTask(
        title: 'Test Task',
        description: 'This is a test task created during unit tests',
        familyId: familyId,
        difficulty: TaskDifficulty.medium,
      );
      
      expect(taskId, isNotNull);
      
      final task = await dataService.getTask(taskId: taskId);
      expect(task, isNotNull);
      expect(task!['title'], equals('Test Task'));
      expect(task['description'], equals('This is a test task created during unit tests'));
      expect(task['status'], equals(TaskStatus.pending.name));
    });

    test('Mock service should complete a task', () async {
      // First create a task
      final taskId = await dataService.createTask(
        title: 'Task to Complete',
        description: 'This task will be completed',
        familyId: familyId,
        difficulty: TaskDifficulty.easy,
        assigneeId: userId,
      );
      
      // Complete the task
      await dataService.completeTask(
        taskId: taskId,
        completedByUserId: userId,
        completionNotes: 'Completed during test',
      );
      
      // Verify task is completed
      final task = await dataService.getTask(taskId: taskId);
      expect(task!['status'], equals(TaskStatus.completed.name));
      expect(task['completedByUserId'], equals(userId));
      expect(task['completionNotes'], equals('Completed during test'));
    });
  });

  testWidgets('App initializes with mock data in test environment', (WidgetTester tester) async {
    // Build our app with the mock data service and mock gamification service
    await tester.pumpWidget(
      MyApp(
        dataService: dataService, 
        gamificationService: mockGamificationService, // Updated constructor
      )
    );
    
    // Verify that the app builds without errors and shows the login screen
    expect(find.text('Login'), findsOneWidget); // Assuming LoginScreen is the initial screen for unauthenticated users
    
    // Verify we're using mock data by checking the Provider
    final context = tester.element(find.byType(MaterialApp));
    final providedDataService = Provider.of<DataService>(context, listen: false);
    expect(providedDataService, isA<MockDataService>());
  });

  testWidgets('AuthProvider works with mock data service', (WidgetTester tester) async {
    // Create a test widget with AuthProvider
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<DataService>.value(value: dataService),
          ChangeNotifierProxyProvider<DataService, AuthProvider>(
            create: (_) => AuthProvider(),
            update: (_, dataService, authProvider) => 
                authProvider!..updateDataService(dataService),
          ),
          // GamificationProvider could be added here if needed for the test
          Provider<GamificationServiceInterface>.value(value: mockGamificationService),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Text('TestWidgetForAuthProvider'), // Unique text to find the context
          ),
        ),
      ),
    );
    
    // Get the AuthProvider
    final context = tester.element(find.text('TestWidgetForAuthProvider'));
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Test sign in
    final success = await authProvider.signIn(
      email: 'ahmed@example.com',
      password: 'password123',
    );
    
    expect(success, isTrue, reason: "Sign-in should succeed with mock credentials");
    expect(authProvider.isLoggedIn, isTrue, reason: "AuthProvider should reflect logged-in state");
    expect(authProvider.userId, isNotNull, reason: "User ID should be available after sign-in");
    expect(authProvider.displayName, isNotNull, reason: "Display name should be available after sign-in");
    
    // Test sign out
    await authProvider.signOut();
    expect(authProvider.isLoggedIn, isFalse, reason: "AuthProvider should reflect logged-out state");
  });

  // Test that output files are generated for test results
  test('Test output files can be written', () {
    // This is just a placeholder - in a real CI environment,
    // the test runner would generate output files based on configuration
    expect(true, isTrue, reason: 'Test output files should be configurable in CI');
  });
}
