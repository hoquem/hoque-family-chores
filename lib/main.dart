import 'package:flutter/material.dart';
import 'package:provider/provider.dart'
    show
        ChangeNotifierProvider,
        Provider,
        Consumer,
        MultiProvider;
import 'package:provider/single_child_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Core Services
import 'package:hoque_family_chores/services/base/environment_service.dart';
import 'package:hoque_family_chores/services/interfaces/gamification_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/task_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/user_profile_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/family_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/badge_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/reward_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/achievement_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/notification_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/leaderboard_service_interface.dart';

// Service Implementations
import 'package:hoque_family_chores/services/implementations/firebase/firebase_task_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_user_profile_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_family_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_badge_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_reward_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_achievement_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_notification_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_gamification_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_task_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_gamification_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_user_profile_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_family_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_badge_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_reward_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_achievement_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_notification_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_leaderboard_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_leaderboard_service.dart';

// Providers
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/presentation/providers/gamification_provider.dart';
import 'package:hoque_family_chores/presentation/providers/task_list_provider.dart';
import 'package:hoque_family_chores/presentation/providers/task_summary_provider.dart';
import 'package:hoque_family_chores/presentation/providers/available_tasks_provider.dart';
import 'package:hoque_family_chores/presentation/providers/my_tasks_provider.dart';
import 'package:hoque_family_chores/presentation/providers/badge_provider.dart';
import 'package:hoque_family_chores/presentation/providers/reward_provider.dart';
import 'package:hoque_family_chores/presentation/providers/task_provider.dart';
import 'package:hoque_family_chores/presentation/providers/family_provider.dart';
import 'package:hoque_family_chores/presentation/providers/mock_auth_provider.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider_base.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider_factory.dart';
import 'package:hoque_family_chores/presentation/providers/leaderboard_provider.dart';

// UI
import 'package:hoque_family_chores/presentation/screens/login_screen.dart';
import 'package:hoque_family_chores/presentation/screens/app_shell.dart';
import 'package:hoque_family_chores/presentation/utils/navigator_key.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'firebase_options.dart';
import 'package:hoque_family_chores/models/shared_enums.dart';

/// Service factory that creates services based on the environment
class ServiceFactory {
  final EnvironmentService _environment;

  ServiceFactory(this._environment);

  /// Creates all services based on the environment
  Map<Type, dynamic> createServices() {
    logger.i('[ServiceFactory] Creating services for environment: ${_environment.useMockData ? 'MOCK' : 'FIREBASE'}');

    final services = <Type, dynamic>{};

    try {
      // Create task service
      logger.d('[ServiceFactory] Creating TaskService...');
      services[TaskServiceInterface] =
          _environment.useMockData ? MockTaskService() : FirebaseTaskService();

      // Create user profile service
      logger.d('[ServiceFactory] Creating UserProfileService...');
      services[UserProfileServiceInterface] = 
          _environment.useMockData ? MockUserProfileService() : FirebaseUserProfileService();

      // Create family service
      logger.d('[ServiceFactory] Creating FamilyService...');
      services[FamilyServiceInterface] = 
          _environment.useMockData ? MockFamilyService() : FirebaseFamilyService();

      // Create badge service
      logger.d('[ServiceFactory] Creating BadgeService...');
      services[BadgeServiceInterface] = 
          _environment.useMockData ? MockBadgeService() : FirebaseBadgeService();

      // Create reward service
      logger.d('[ServiceFactory] Creating RewardService...');
      services[RewardServiceInterface] = 
          _environment.useMockData ? MockRewardService() : FirebaseRewardService();

      // Create achievement service
      logger.d('[ServiceFactory] Creating AchievementService...');
      services[AchievementServiceInterface] = 
          _environment.useMockData ? MockAchievementService() : FirebaseAchievementService();

      // Create notification service
      logger.d('[ServiceFactory] Creating NotificationService...');
      services[NotificationServiceInterface] = 
          _environment.useMockData ? MockNotificationService() : FirebaseNotificationService();

      // Create gamification service
      logger.d('[ServiceFactory] Creating GamificationService...');
      services[GamificationServiceInterface] =
          _environment.useMockData
              ? MockGamificationService()
              : FirebaseGamificationService();

      // Create leaderboard service
      logger.d('[ServiceFactory] Creating LeaderboardService...');
      services[LeaderboardServiceInterface] =
          _environment.useMockData ? MockLeaderboardService() : FirebaseLeaderboardService();
      logger.d('[ServiceFactory] LeaderboardService created: ${services[LeaderboardServiceInterface]?.runtimeType}');

      logger.i('[ServiceFactory] All services created successfully. Total services: ${services.length}');
    } catch (e, s) {
      logger.e('[ServiceFactory] Error creating services: $e', error: e, stackTrace: s);
      rethrow;
    }

    return services;
  }
}

void main() async {
  final logger = AppLogger();
  logger.init(); // Initialize the logger first

  try {
    logger.i("[Startup] Initializing Flutter bindings...");
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables (optional)
    try {
      logger.i("[Startup] Attempting to load .env file...");
      await dotenv.load(fileName: ".env");
      logger.i("[Startup] Loaded .env file for configuration secrets.");
    } catch (e) {
      logger.w("[Startup] No .env file found, using default configuration. Error: $e");
    }

    // Initialize environment service
    logger.i("[Startup] Initializing environment service...");
    final environmentService = EnvironmentService();
    logger.i(
      "[Startup] Environment checks: Debug Mode = ${environmentService.isDebugMode}, Use Mock Data = ${environmentService.useMockData}",
    );

    // Initialize Firebase if needed
    if (environmentService.shouldConnectToFirebase) {
      try {
        logger.i("[Startup] Connecting to Firebase...");
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        logger.i("[Startup] Firebase connected successfully.");
      } catch (e, s) {
        logger.e("[Startup] Firebase initialization failed.", error: e, stackTrace: s);
        rethrow;
      }
    } else {
      logger.w("[Startup] Firebase connection skipped (using mock data). UseMockData: ${environmentService.useMockData}");
    }

    // Create services
    logger.i("[Startup] Creating service factory and initializing services...");
    final serviceFactory = ServiceFactory(environmentService);
    final services = serviceFactory.createServices();
    logger.i("[Startup] Services initialized successfully");

    // Run the app
    logger.i("[Startup] Running the app...");
    runApp(MyApp(services: services.cast<Type, Object>(), useMockData: environmentService.useMockData));
  } catch (e, stackTrace) {
    logger.e(
      "[Startup] A fatal error occurred during app startup.",
      error: e,
      stackTrace: stackTrace,
    );
    runApp(ErrorApp(error: e));
  }
}

class MyApp extends StatelessWidget {
  final Map<Type, Object> services;
  final bool useMockData;

  const MyApp({
    super.key,
    required this.services,
    required this.useMockData,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _buildProviders(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Hoque Family Chores',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: Consumer<AuthProviderBase>(
          builder: (context, authProvider, _) {
            return _buildHomeScreen(authProvider);
          },
        ),
      ),
    );
  }

  List<SingleChildWidget> _buildProviders() {
    final providers = <SingleChildWidget>[];

    // Add service providers
    services.forEach((type, service) {
      providers.add(Provider.value(value: service));
    });

    // Create auth provider using factory
    final authProvider = AuthProviderFactory.create(useMock: useMockData);
    providers.add(ChangeNotifierProvider<AuthProviderBase>.value(value: authProvider));

    // Add state management providers
    providers.addAll([
      ChangeNotifierProvider<GamificationProvider>(
        create: (_) => GamificationProvider(
          gamificationService: services[GamificationServiceInterface] as GamificationServiceInterface,
        ),
      ),
      ChangeNotifierProvider<TaskListProvider>(
        create: (context) => TaskListProvider(
          taskService: services[TaskServiceInterface] as TaskServiceInterface,
          authProvider: Provider.of<AuthProviderBase>(context, listen: false),
        ),
      ),
      ChangeNotifierProvider<TaskSummaryProvider>(
        create: (context) => TaskSummaryProvider(
          taskService: services[TaskServiceInterface] as TaskServiceInterface,
          authProvider: Provider.of<AuthProviderBase>(context, listen: false),
        ),
      ),
      ChangeNotifierProvider<AvailableTasksProvider>(
        create: (context) => AvailableTasksProvider(
          taskService: services[TaskServiceInterface] as TaskServiceInterface,
          authProvider: Provider.of<AuthProviderBase>(context, listen: false),
        ),
      ),
      ChangeNotifierProvider<MyTasksProvider>(
        create: (context) => MyTasksProvider(
          taskService: services[TaskServiceInterface] as TaskServiceInterface,
          authProvider: Provider.of<AuthProviderBase>(context, listen: false),
        ),
      ),
      ChangeNotifierProvider<BadgeProvider>(
        create: (context) => BadgeProvider(
          services[BadgeServiceInterface] as BadgeServiceInterface,
          Provider.of<AuthProviderBase>(context, listen: false),
        ),
      ),
      ChangeNotifierProvider<RewardProvider>(
        create: (_) => RewardProvider(
          services[RewardServiceInterface] as RewardServiceInterface,
        ),
      ),
      ChangeNotifierProvider<TaskProvider>(
        create: (_) => TaskProvider(
          services[TaskServiceInterface] as TaskServiceInterface,
        ),
      ),
      ChangeNotifierProvider<FamilyProvider>(
        create: (_) => FamilyProvider(
          services[FamilyServiceInterface] as FamilyServiceInterface,
        ),
      ),
      ChangeNotifierProvider<LeaderboardProvider>(
        create: (_) {
          logger.d('[Main] Creating LeaderboardProvider');
          final service = services[LeaderboardServiceInterface] as LeaderboardServiceInterface;
          logger.d('[Main] LeaderboardService type: ${service.runtimeType}');
          final provider = LeaderboardProvider(leaderboardService: service);
          logger.d('[Main] LeaderboardProvider created successfully');
          return provider;
        },
      ),
      Provider<FamilyServiceInterface>(
        create: (_) {
          logger.d('[Main] Providing FamilyServiceInterface');
          return services[FamilyServiceInterface] as FamilyServiceInterface;
        },
      ),
    ]);

    return providers;
  }

  Widget _buildHomeScreen(AuthProviderBase authProvider) {
    logger.d("[App] Building home screen. Auth status: ${authProvider.status}, Loading: ${authProvider.isLoading}");
    
    // Show loading screen while determining auth status
    if (authProvider.status == AuthStatus.unknown || authProvider.isLoading) {
      logger.i("[App] Showing loading screen - status: ${authProvider.status}, loading: ${authProvider.isLoading}");
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Show authenticated user the main app
    if (authProvider.status == AuthStatus.authenticated) {
      logger.i("[App] User authenticated - showing AppShell. User: ${authProvider.currentUserProfile?.member.id}");
      return const AppShell();
    } 
    
    // Show login screen for unauthenticated users
    if (authProvider.status == AuthStatus.unauthenticated) {
      logger.i("[App] User unauthenticated - showing LoginScreen");
      return const LoginScreen();
    }
    
    // Show error screen for authentication errors
    if (authProvider.status == AuthStatus.error) {
      logger.e("[App] Authentication error - showing error screen. Error: ${authProvider.errorMessage}");
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Authentication Error',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                authProvider.errorMessage ?? 'Unknown error occurred',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  logger.i("[App] User clicked retry button - refreshing auth status");
                  // Try to refresh auth status
                  authProvider.refreshUserProfile();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Fallback to login screen
    logger.w("[App] Unknown auth status - falling back to LoginScreen. Status: ${authProvider.status}");
    return const LoginScreen();
  }
}

class ErrorApp extends StatelessWidget {
  final Object error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'An error occurred during startup',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
