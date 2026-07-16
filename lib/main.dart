import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// UI
import 'package:hoque_family_chores/presentation/screens/login_screen.dart';
import 'package:hoque_family_chores/presentation/screens/main_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:hoque_family_chores/core/fresh_install_guard.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/utils/navigator_key.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'firebase_options.dart';
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

      // Setup Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      logger.i("[Startup] Firebase Crashlytics configured.");

      // Enable Firestore offline persistence
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      logger.i("[Startup] Firestore offline persistence enabled.");

      // The iOS keychain keeps the Firebase session across app deletion; a
      // fresh install must start signed out, not resurrect the old session.
      final prefs = await SharedPreferences.getInstance();
      await FreshInstallGuard.run(
        prefs: prefs,
        signOut: () => FirebaseAuth.instance.signOut(),
      );
      logger.i("[Startup] Fresh-install guard completed.");
    } catch (e, s) {
      logger.e("[Startup] Firebase initialization failed.", error: e, stackTrace: s);
      runApp(ErrorApp(error: e));
      return;
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

    // Global error widget
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Center(
          child: Text('Something went wrong', style: const TextStyle(color: Color(0xFFC6412A))),
        ),
      );
    };

    // Run the app with Riverpod
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
      title: 'Chores Star',
      // "Fridge Door" palette (DESIGN.md): marigold seed, star-gold secondary,
      // coral tertiary, brick error, warm-cream surfaces. fromSeed derives
      // onPrimary as dark (marigold is light), so default FilledButton text is
      // already AA-safe Ink — never override to white.
      theme: appLightTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }
          if (snapshot.hasError) {
            // Handle auth token expiry or other auth errors
            final error = snapshot.error;
            if (error is FirebaseAuthException) {
              FirebaseAuth.instance.signOut();
            }
            return const LoginScreen();
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
                const Icon(Icons.error_outline, color: Color(0xFFC6412A), size: 60),
                const SizedBox(height: 16),
                const Text(
                  'An error occurred during startup',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Color(0xFFC6412A)),
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

/// Splash screen with timeout — if Firebase takes too long, show an error
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _timedOut = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home_rounded, size: 64, color: Color(0xFFE08A1E)),
              const SizedBox(height: 24),
              const Text(
                'Our Family Chores',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (!_timedOut) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Connecting...', style: TextStyle(color: Color(0xFF8A8067))),
              ] else ...[
                const Icon(Icons.cloud_off, size: 48, color: Color(0xFFF59E0B)),
                const SizedBox(height: 16),
                const Text(
                  'Unable to connect to the server.\n\nPlease check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _timedOut = false);
                    Future.delayed(const Duration(seconds: 10), () {
                      if (mounted) setState(() => _timedOut = true);
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
