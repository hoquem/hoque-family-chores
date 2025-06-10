import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Services & Factories
import 'package:hoque_family_chores/services/environment_service.dart';
import 'package:hoque_family_chores/services/data_service_factory.dart';
import 'package:hoque_family_chores/services/gamification_service_factory.dart';
import 'package:hoque_family_chores/services/data_service_interface.dart' as app_data_service_interface;
import 'package:hoque_family_chores/services/gamification_service_interface.dart';
import 'package:hoque_family_chores/services/task_service.dart';
import 'package:hoque_family_chores/services/task_service_interface.dart';
import 'package:hoque_family_chores/services/logging_service.dart';

// Providers
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart' as app_auth_provider;
import 'package:hoque_family_chores/presentation/providers/gamification_provider.dart' as app_gamification_provider;
import 'package:hoque_family_chores/presentation/providers/task_list_provider.dart';

// UI
import 'package:hoque_family_chores/presentation/screens/login_screen.dart';
import 'package:hoque_family_chores/presentation/screens/dashboard_screen.dart';
import 'firebase_options.dart';

// Ensure AuthStatus is available by importing enums.dart
import 'package:hoque_family_chores/models/enums.dart'; // <--- Ensure this import is here

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    logger.i("App starting up...");

    await dotenv.load(fileName: ".env");
    logger.i("Loaded .env file for configuration secrets.");

    final environmentService = EnvironmentService();
    logger.i(
        "Environment checks: Debug Mode = ${environmentService.isDebugMode}, "
        "Use Mock Data = ${environmentService.useMockData}");

    if (environmentService.shouldConnectToFirebase) {
      logger.i("Connecting to Firebase...");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      logger.i("Firebase connected successfully.");
    } else {
      logger.w("Firebase connection skipped (using mock data).");
    }

    logger.i("Initializing services using factories...");
    final app_data_service_interface.DataServiceInterface dataService = DataServiceFactory.getDataService();
    final GamificationServiceInterface gamificationService = GamificationServiceFactory.getGamificationService();
    logger.i("Services initialized: ${dataService.runtimeType}, ${gamificationService.runtimeType}");

    runApp(MyApp(
      dataService: dataService,
      gamificationService: gamificationService,
    ));
  } catch (e, stackTrace) {
    logger.f("A fatal error occurred during app startup.", error: e, stackTrace: stackTrace);
    runApp(ErrorApp(error: e));
  }
}

class MyApp extends StatelessWidget {
  final app_data_service_interface.DataServiceInterface dataService;
  final GamificationServiceInterface gamificationService;

  const MyApp({
    super.key,
    required this.dataService,
    required this.gamificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- Core Service Providers ---
        Provider<app_data_service_interface.DataServiceInterface>.value(value: dataService),
        Provider<GamificationServiceInterface>.value(value: gamificationService),

        // --- Dependent Service Providers (Adapters) ---
        ProxyProvider<app_data_service_interface.DataServiceInterface, TaskServiceInterface>(
          update: (_, dataService, __) => TaskService(dataService),
        ),

        // --- State Management Providers ---
        ChangeNotifierProvider<app_auth_provider.AuthProvider>(
          create: (context) => app_auth_provider.AuthProvider(dataService: dataService),
        ),

        ChangeNotifierProxyProvider2<GamificationServiceInterface, app_data_service_interface.DataServiceInterface, app_gamification_provider.GamificationProvider>(
          create: (context) => app_gamification_provider.GamificationProvider(),
          update: (_, gamificationService, dataService, provider) =>
              provider!..updateDependencies(
                gamificationService: gamificationService,
                dataService: dataService,
              ),
        ),

        ChangeNotifierProxyProvider<app_auth_provider.AuthProvider, TaskListProvider>(
          create: (context) => TaskListProvider(),
          update: (context, authProvider, taskListProvider) {
            final taskService = context.read<TaskServiceInterface>();
            return taskListProvider!..update(taskService, authProvider);
          },
        ),
      ],
      child: MaterialApp(
        title: 'Family Chores',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app_auth_provider.AuthProvider>();
    switch (authProvider.status) {
      case AuthStatus.authenticated: // Uses AuthStatus from enums.dart
        return const DashboardScreen();
      case AuthStatus.unauthenticated: // Uses AuthStatus from enums.dart
        return const LoginScreen();
      case AuthStatus.unknown: // Uses AuthStatus from enums.dart
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticating: // Uses AuthStatus from enums.dart
        return const Scaffold(
          body: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Authenticating...'),
            ],
          )),
        );
      case AuthStatus.error: // Uses AuthStatus from enums.dart
        return Scaffold(
          body: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 50),
              const SizedBox(height: 16),
              Text(
                'Authentication Error: ${authProvider.errorMessage ?? "Unknown error"}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // This should trigger a public method to re-attempt init/login
                  // Example: authProvider.retryInitialization();
                },
                child: const Text('Retry'),
              ),
            ],
          )),
        );
    }
  }
}

/// A simple widget to display a fatal error message when the app fails to start.
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
            child: Text(
              'A critical error occurred and the app cannot start.\n\nError: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}