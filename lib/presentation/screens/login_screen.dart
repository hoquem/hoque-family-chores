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

  // Email/password auth exists for App Store review validation only;
  // families sign in with Apple or Google. Long-pressing the Login title
  // reveals it (documented in the App Store review notes).
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
        // Email sign-in hides behind a long-press on the title. The gesture
        // has no visual affordance, so without an explicit Semantics action a
        // screen-reader user cannot discover it or perform it — PRODUCT.md
        // requires the label + action on every non-standard gesture.
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
            if (authState.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 24.0),
                child: CircularProgressIndicator(),
              ),
            if (authState.errorMessage != null &&
                authState.errorMessage!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  authState.errorMessage!,
                  style: TextStyle(color: context.tokens.brick),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_showEmailAuth) ..._emailAuthSection(authState.isLoading),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _emailAuthSection(bool isLoading) {
    return [
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
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
      TextField(
        controller: _emailController,
        decoration: const InputDecoration(labelText: 'Email'),
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _passwordController,
        decoration: const InputDecoration(labelText: 'Password'),
        obscureText: true,
      ),
      const SizedBox(height: 24),
      if (!isLoading)
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
    ];
  }
}
