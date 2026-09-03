// lib/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/child_join_screen.dart';
import 'package:hoque_family_chores/presentation/screens/registration_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showEmailAuth = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        // Email sign-in can be toggled via long-press on the title (documented
        // in App Store review notes) or via the text button below.
        title: Semantics(
          label: 'Login',
          hint: _showEmailAuth
              ? 'Long press to hide email sign in'
              : 'Long press to show email sign in',
          onLongPress: () => setState(() => _showEmailAuth = !_showEmailAuth),
          excludeSemantics: true,
          child: GestureDetector(
            onLongPress: () => setState(() => _showEmailAuth = !_showEmailAuth),
            child: const Text('Login'),
          ),
        ),
      ),
      // Scrollable: with the email section revealed (and the keyboard up on
      // small phones) the content is taller than the screen.
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SignInWithAppleButton(
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).signInWithApple(),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).signInWithGoogle(),
                icon: const Icon(Icons.account_circle),
                label: const Text('Continue with Google'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChildJoinScreen()),
                ),
                icon: const Icon(Icons.child_care),
                label: const Text("I'm a kid — join my family"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    setState(() => _showEmailAuth = !_showEmailAuth),
                child: Text(
                  _showEmailAuth
                      ? 'Hide email sign in'
                      : 'Use email sign in',
                  style: TextStyle(color: context.tokens.inkSoft),
                ),
              ),
              if (_showEmailAuth) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text('or use email'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),
                // App Review / password account path
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'reviewer@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'Demo account password',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                Text(
                  'For App Review: use the demo account from the App Review Information section.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.tokens.inkSoft,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (!authState.isLoading)
                  ElevatedButton(
                    onPressed: () async {
                      await ref.read(authNotifierProvider.notifier).signIn(
                            email: _emailController.text,
                            password: _passwordController.text,
                          );
                    },
                    child: const Text('Sign In'),
                  ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(authNotifierProvider.notifier)
                        .resetPassword(_emailController.text);
                  },
                  child: const Text('Forgot Password?'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegistrationScreen(),
                      ),
                    );
                  },
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ],
              if (authState.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 24.0),
                  child: CircularProgressIndicator(),
                ),
              if (authState.errorMessage != null &&
                  authState.errorMessage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.tokens.brick.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      authState.errorMessage!,
                      style: TextStyle(color: context.tokens.brickDeep),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
