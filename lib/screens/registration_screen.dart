import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import your home screen to navigate after registration
// For example: import 'home_screen.dart';
// Import your login screen to navigate (e.g., if already has account button is pressed)
// import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  // String _username = ''; // Uncomment if you added a username field
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _tryRegister() async { // Made this async
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus(); // Close keyboard

    if (isValid) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _email.trim(), // Use trim() to remove leading/trailing whitespace
          password: _password.trim(),
        );

        print('User registered: ${userCredential.user!.uid}');

        // Optional: Update user profile with username if you have one
        // if (userCredential.user != null && _username.isNotEmpty) {
        //   await userCredential.user!.updateDisplayName(_username.trim());
        // }

        // Navigate to HomeScreen or another appropriate screen after successful registration
        // Ensure you have a HomeScreen created and imported.
        // For now, we can print a success message or pop the screen.
        if (mounted) { // Check if the widget is still in the tree
          // Example: Navigate to a placeholder home screen
          // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
          
          // Or show a success message and pop if registration is part of a flow
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration successful! UID: ${userCredential.user!.uid}'),
              backgroundColor: Colors.green,
            ),
          );
          // If you want to go back to login screen or clear navigation stack to a home screen:
          // Navigator.of(context).popUntil((route) => route.isFirst); // Clears stack to the first route
          // Navigator.of(context).pushReplacementNamed('/home'); // Assuming you have a '/home' route
          
          // For now, let's pop this screen if it was pushed on top of login
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }

      } on FirebaseAuthException catch (e) {
        String message = 'An error occurred, please check your credentials!';
        if (e.code == 'weak-password') {
          message = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          message = 'The account already exists for that email.';
        } else if (e.code == 'invalid-email') {
          message = 'The email address is not valid.';
        }
        // For other Firebase errors, e.message might be more descriptive
        // else { message = e.message ?? message; }

        setState(() {
          _errorMessage = message;
        });
        print('Firebase Auth Exception: ${e.code} - ${e.message}');
      } catch (e) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
        print('Unexpected error: $e');
      } finally {
        if (mounted) { // Check if the widget is still in the tree
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< Updated upstream
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
                  onPressed: _tryRegister,
                  child: Text('Register'),
                ),
              if (_errorMessage != null && !_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
=======
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Center( // Added Center to keep form from stretching full height if content is small
        child: SingleChildScrollView( // Added SingleChildScrollView for smaller screens
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Create Your Account',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
>>>>>>> Stashed changes
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  // Optional: TextFormField for Username
                  // TextFormField(
                  //   key: ValueKey('username'),
                  //   decoration: InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                  //   validator: (value) {
                  //     if (value == null || value.isEmpty || value.trim().length < 4) {
                  //       return 'Please enter at least 4 characters.';
                  //     }
                  //     return null;
                  //   },
                  //   onSaved: (value) {
                  //     _username = value!;
                  //   },
                  // ),
                  // SizedBox(height: 12),
                  TextFormField(
                    key: ValueKey('email_register'), // Changed key to avoid clashes if on same page later
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty || !value.trim().contains('@')) {
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
                    key: ValueKey('password_register'), // Changed key
                    decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty || value.trim().length < 6) {
                        return 'Password must be at least 6 characters long.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _password = value!;
                    },
                  ),
                  SizedBox(height: 25),
                  if (_isLoading)
                    Center(child: CircularProgressIndicator()) // Centered indicator
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                      child: Text('Register'),
                      onPressed: _tryRegister,
                    ),
                  if (_errorMessage != null && !_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(height: 15),
                  TextButton(
                    child: Text('Already have an account? Login'),
                    onPressed: _isLoading ? null : () { // Disable button when loading
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop(); // Goes back to login if pushed
                      } else {
                        // Fallback if it can't pop (e.g. if it's the first screen)
                        // Navigator.of(context).pushReplacementNamed('/login');
                        // Or: Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
                        print("Navigate to login screen (cannot pop)");
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}