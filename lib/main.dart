import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/presentation/providers/gamification_provider.dart';
import 'package:hoque_family_chores/presentation/providers/task_list_provider.dart';
import 'package:hoque_family_chores/presentation/screens/login_screen.dart';
import 'package:hoque_family_chores/presentation/screens/dashboard_screen.dart';
import 'package:hoque_family_chores/services/environment_service.dart';
import 'package:hoque_family_chores/services/data_service_factory.dart';
import 'package:hoque_family_chores/services/data_service_interface.dart';
import 'package:hoque_family_chores/services/gamification_service_interface.dart';
import 'package:hoque_family_chores/services/mock_gamification_service.dart';
import 'package:hoque_family_chores/services/task_service.dart';
import 'package:hoque_family_chores/services/task_service_interface.dart';
import 'firebase_options.dart';

void main() async { 
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  final environmentService = EnvironmentService();
  
  if (environmentService.shouldConnectToFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  final DataServiceInterface dataService = DataServiceFactory.getDataService();
  final GamificationServiceInterface gamificationService = MockGamificationService(); 
  
  runApp(MyApp(
    dataService: dataService,
    gamificationService: gamificationService,
  ));
}

class MyApp extends StatelessWidget {
  final DataServiceInterface dataService;
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
        Provider<DataServiceInterface>.value(value: dataService),
        Provider<GamificationServiceInterface>.value(value: gamificationService),
        ProxyProvider<DataServiceInterface, TaskServiceInterface>(
          update: (_, dataService, __) => TaskService(dataService),
        ),
        ChangeNotifierProxyProvider<DataServiceInterface, AuthProvider>(
          create: (_) => AuthProvider(),
          update: (_, dataService, authProvider) => 
              authProvider!..updateDataService(dataService),
        ),
        
        // MODIFIED: This provider now correctly depends on two services
        // and calls the 'updateDependencies' method.
        ChangeNotifierProxyProvider2<GamificationServiceInterface, DataServiceInterface, GamificationProvider>(
          create: (_) => GamificationProvider(),
          update: (_, gamificationService, dataService, provider) => 
              provider!..updateDependencies(
                gamificationService: gamificationService,
                dataService: dataService,
              ),
        ),

        ChangeNotifierProxyProvider2<TaskServiceInterface, AuthProvider, TaskListProvider>(
          create: (_) => TaskListProvider(),
          update: (_, taskService, authProvider, taskListProvider) =>
              taskListProvider!..update(taskService, authProvider),
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
    final authProvider = Provider.of<AuthProvider>(context);
    switch (authProvider.status) {
      case AuthStatus.authenticated:
        return const DashboardScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
    }
  }
}