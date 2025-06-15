import 'package:flutter/material.dart';
import 'package:provider/provider.dart'
    show
        ChangeNotifierProvider,
        ChangeNotifierProxyProvider2,
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

// Providers
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/presentation/providers/gamification_provider.dart';
import 'package:hoque_family_chores/presentation/providers/task_list_provider.dart';
import 'package:hoque_family_chores/presentation/providers/task_summary_provider.dart';
import 'package:hoque_family_chores/presentation/providers/available_tasks_provider.dart';
import 'package:hoque_family_chores/presentation/providers/my_tasks_provider.dart';

// UI
import 'package:hoque_family_chores/presentation/screens/login_screen.dart';
import 'package:hoque_family_chores/presentation/screens/app_shell.dart';
import 'package:hoque_family_chores/presentation/screens/family_setup_screen.dart';
import 'package:hoque_family_chores/presentation/utils/navigator_key.dart';
import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'firebase_options.dart';

/// Service factory that creates services based on the environment
class ServiceFactory {
  final EnvironmentService _environment;
  final _logger = AppLogger();

  ServiceFactory(this._environment);

  /// Creates all services based on the environment
  Map<Type, dynamic> createServices() {
    _logger.i(
      'Creating services for environment: ${_environment.useMockData ? 'MOCK' : 'FIREBASE'}',
    );

    final services = <Type, dynamic>{};

    // Create task service
    services[TaskServiceInterface] =
        _environment.useMockData ? MockTaskService() : FirebaseTaskService();

    // Create user profile service
    services[UserProfileServiceInterface] = FirebaseUserProfileService();

    // Create family service
    services[FamilyServiceInterface] = FirebaseFamilyService();

    // Create badge service
    services[BadgeServiceInterface] = FirebaseBadgeService();

    // Create reward service
    services[RewardServiceInterface] = FirebaseRewardService();

    // Create achievement service
    services[AchievementServiceInterface] = FirebaseAchievementService();

    // Create notification service
    services[NotificationServiceInterface] = FirebaseNotificationService();

    // Create gamification service
    services[GamificationServiceInterface] =
        _environment.useMockData
            ? MockGamificationService()
            : FirebaseGamificationService();

    return services;
  }
}

void main() async {
  final logger = AppLogger();
  try {
    // Initialize Flutter bindings
    WidgetsFlutterBinding.ensureInitialized();
    logger.i("App starting up...");

    // Load environment variables
    await dotenv.load(fileName: ".env");
    logger.i("Loaded .env file for configuration secrets.");

    // Initialize environment service
    final environmentService = EnvironmentService();
    logger.i(
      "Environment checks: Debug Mode = ${environmentService.isDebugMode}, "
      "Use Mock Data = ${environmentService.useMockData}",
    );

    // Initialize Firebase if needed
    if (environmentService.shouldConnectToFirebase) {
      logger.i("Connecting to Firebase...");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      logger.i("Firebase connected successfully.");
    } else {
      logger.w("Firebase connection skipped (using mock data).");
    }

    // Create services
    final serviceFactory = ServiceFactory(environmentService);
    final services = serviceFactory.createServices();
    logger.i("Services initialized successfully");

    // Run the app
    runApp(MyApp(services: services));
  } catch (e, stackTrace) {
    logger.e(
      "A fatal error occurred during app startup.",
      error: e,
      stackTrace: stackTrace,
    );
    runApp(ErrorApp(error: e));
  }
}

class MyApp extends StatelessWidget {
  final Map<Type, dynamic> services;

  const MyApp({super.key, required this.services});

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
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.status == AuthStatus.authenticated) {
              return const AppShell();
            } else if (authProvider.status == AuthStatus.unauthenticated) {
              return const LoginScreen();
            } else {
              return const FamilySetupScreen();
            }
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

    // Add state management providers
    providers.addAll([
      ChangeNotifierProvider<AuthProvider>(
        create:
            (context) => AuthProvider(
              userProfileService: services[UserProfileServiceInterface],
              gamificationService: services[GamificationServiceInterface],
            ),
      ),

      ChangeNotifierProvider<GamificationProvider>(
        create:
            (context) => GamificationProvider(
              gamificationService: services[GamificationServiceInterface],
            ),
      ),

      ChangeNotifierProxyProvider2<
        TaskServiceInterface,
        AuthProvider,
        MyTasksProvider
      >(
        create: (context) => MyTasksProvider(),
        update:
            (_, taskService, authProvider, provider) =>
                provider!..update(taskService, authProvider),
      ),

      ChangeNotifierProxyProvider2<
        TaskServiceInterface,
        AuthProvider,
        TaskListProvider
      >(
        create:
            (context) => TaskListProvider(
              taskService: services[TaskServiceInterface],
              authProvider: Provider.of<AuthProvider>(context, listen: false),
            ),
        update:
            (_, taskService, authProvider, provider) =>
                provider!..update(taskService, authProvider),
      ),

      ChangeNotifierProxyProvider2<
        TaskServiceInterface,
        AuthProvider,
        AvailableTasksProvider
      >(
        create:
            (context) => AvailableTasksProvider(
              taskService: services[TaskServiceInterface],
              authProvider: Provider.of<AuthProvider>(context, listen: false),
            ),
        update:
            (_, taskService, authProvider, provider) =>
                provider!..update(taskService, authProvider),
      ),

      ChangeNotifierProxyProvider2<
        TaskServiceInterface,
        AuthProvider,
        TaskSummaryProvider
      >(
        create:
            (context) => TaskSummaryProvider(
              taskService: services[TaskServiceInterface],
              authProvider: Provider.of<AuthProvider>(context, listen: false),
            ),
        update:
            (_, taskService, authProvider, provider) =>
                provider!..update(taskService, authProvider),
      ),
    ]);

    return providers;
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
