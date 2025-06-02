import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// TODO: Make sure you have created this file and RegistrationScreen widget
import 'registration_screen.dart'; // Import your registration screen

// If you have a HomeScreen, you might import it here:
// import 'home_screen.dart'; // Example

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String? _errorMessage;

  // --- Firebase Email/Password Login Logic (from previous response) ---
  // This method already implements Firebase email/password login.
  void _tryLogin() async {
    final isValid = _formKey.currentState?.validate();
    if (isValid == null || !isValid) {
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _email.trim(),
        password: _password,
      );
      print('Successfully logged in: ${userCredential.user?.uid}');
      // TODO: Navigate to the home screen after successful login
      // if (mounted) {
      //   Navigator.of(context).pushReplacement(
      //     MaterialPageRoute(builder: (context) => HomeScreen()),
      //   );
      // }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided for that user.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many login attempts. Please try again later.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your connection.';
          break;
        default:
          message = e.message ?? 'An unexpected error occurred.';
      }
      setState(() {
        _errorMessage = message;
      });
      print('Firebase Auth Exception (${e.code}): ${e.message}');
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
      print('Unexpected Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // --- End of Firebase Email/Password Login Logic ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Welcome Back!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TextFormField(
                key: ValueKey('email'),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty || !value.trim().contains('@')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                onSaved: (value) {
                  _email = value!;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                key: ValueKey('password'),
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
                onSaved: (value) {
                  _password = value!;
                },
              ),
              SizedBox(height: 20),
              if (_isLoading) Center(child: CircularProgressIndicator()),
              if (!_isLoading)
                ElevatedButton(onPressed: _tryLogin, child: Text('Login')),
              if (_errorMessage != null && !_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: 12),
              // --- Navigation to Registration Screen Implemented Here ---
              TextButton(
                onPressed: _isLoading ? null : () {
                  // Navigate to RegistrationScreen
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => RegistrationScreen()),
                  );
                  print('Navigating to registration screen');
                },
                child: Text('Don\'t have an account? Register'),
              ),
              // --- End of Navigation ---
            ],
          ),
        ),
      ),
    );
  }
}