import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// UI
import 'package:hoque_family_chores/presentation/screens/login_screen.dart';
import 'package:hoque_family_chores/presentation/screens/main_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:hoque_family_chores/presentation/utils/navigator_key.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'firebase_options.dart';

// Custom theme colors extension
class CustomColors extends ThemeExtension<CustomColors> {
  final Color success;
  final Color starGold;

  const CustomColors({
    required this.success,
    required this.starGold,
  });

  @override
  CustomColors copyWith({Color? success, Color? starGold}) {
    return CustomColors(
      success: success ?? this.success,
      starGold: starGold ?? this.starGold,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      success: Color.lerp(success, other.success, t)!,
      starGold: Color.lerp(starGold, other.starGold, t)!,
    );
  }
}

// Push notifications background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final logger = AppLogger();
  logger.i('[FCM Background] Message received: ${message.notification?.title}');
}

void main() async {
  final logger = AppLogger();
  logger.init();

  try {
    logger.i("[Startup] Initializing Flutter bindings...");
    WidgetsFlutterBinding.ensureInitialized();

    try {
      logger.i("[Startup] Attempting to load .env file...");
      await dotenv.load(fileName: ".env");
      logger.i("[Startup] Loaded .env file for configuration secrets.");
    } catch (e) {
      logger.w("[Startup] No .env file found, using default configuration. Error: $e");
    }

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

    try {
      logger.i("[Startup] Initializing timezone database...");
      tz.initializeTimeZones();
      logger.i("[Startup] Timezone database initialized.");
    } catch (e, s) {
      logger.e("[Startup] Timezone initialization failed.", error: e, stackTrace: s);
    }

    try {
      logger.i("[Startup] Setting up FCM background handler...");
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      logger.i("[Startup] FCM background handler configured.");
    } catch (e, s) {
      logger.e("[Startup] FCM background handler setup failed.", error: e, stackTrace: s);
    }

    logger.i("[Startup] Running the app with Riverpod...");
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Hoque Family Chores',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          primary: const Color(0xFF6750A4),
          secondary: const Color(0xFFFFB300),
          error: const Color(0xFFF44336),
        ),
        useMaterial3: true,
        primaryColor: const Color(0xFF6750A4),
        extensions: const <ThemeExtension<dynamic>>[
          CustomColors(
            success: Color(0xFF4CAF50),
            starGold: Color(0xFFFFB300),
          ),
        ],
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const MainScreen();
          }
          return const LoginScreen();
        },
      ),
    );
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
