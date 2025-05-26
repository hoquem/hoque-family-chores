import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import your login screen to navigate after registration (optional)
// Import 'login_screen.dart';
// Import your home screen to navigate after registraion
// import 'home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  // String _username = ''; // Optional: if you want to collect a username
  bool _isLoading = false;
  String? _errorMessage;

  void _tryRegister() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        // TODO: Implement Firebase Registration Logic
        print('Register with Email: $_email, Passowrd: $_password');
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message;
        });
        print('Firebase Auth Exception: ${e.message}');
      } catch (e) {
        setState(() {
          _errorMessage = 'An unexpected error occured.';
        });
        print('Unexpected error: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Create Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TextFormField(
                key: ValueKey('email'),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email.';
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
                    return 'Password must be at least 6 characters long.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _password = value!;
                },
              ),
              SizedBox(height: 20),
              if (_isLoading) CircularProgressIndicator(),
              if (!_isLoading)
                ElevatedButton(
                  child: Text('Register'),
                  onPressed: _tryRegister,
                ),
              if (_errorMessage != null && !_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: 12),
              TextButton(
                child: Text('Already have an account? Login'),
                onPressed: () {
                  // Navigate back or to LoginScreen
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
                  }
                  print("Navigate to login screen");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
