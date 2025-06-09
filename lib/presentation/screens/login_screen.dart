// lib/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/presentation/screens/registration_screen.dart'; // Ensure this is imported

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles the sign-in logic, including form validation and showing feedback.
  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do nothing.
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Call the signIn method from the provider
    final bool success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    
    // After the attempt, if the widget is still on screen, show feedback.
    if (mounted) {
      // On SUCCESS, the AuthWrapper will handle navigation automatically.
      // On FAILURE, we show the error message from the provider.
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'An unknown error occurred.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      // Note: We do NOT navigate here on success. The AuthWrapper handles that.
      // This keeps the logic clean and separates concerns.
    }
  }

  /// Handles the password reset logic.
  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email to reset password.')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.resetPassword(email: _emailController.text.trim());

    if (mounted) {
      final message = authProvider.errorMessage ?? 'Request sent.';
      final color = message.contains('success') ? Colors.green : Colors.redAccent;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }
  
  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the provider to get the loading state for disabling UI elements.
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.home_work_outlined,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Family Chores',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColorDark,
                      ),
                ),
                const SizedBox(height: 48),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: !authProvider.isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Please enter your email';
                    if (!value.contains('@')) return 'Please enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  enabled: !authProvider.isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your password';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: authProvider.isLoading ? null : _resetPassword,
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('SIGN IN', style: TextStyle(fontSize: 16, letterSpacing: 1.2)),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: authProvider.isLoading ? null : _navigateToSignUp,
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}