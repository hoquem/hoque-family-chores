import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider_base.dart';
import 'package:hoque_family_chores/presentation/providers/family_provider.dart';
import 'package:hoque_family_chores/models/shared_enums.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class FamilySetupScreen extends StatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  final _familyNameController = TextEditingController();
  final _logger = AppLogger();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _familyNameController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    if (_familyNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Family name cannot be empty.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProviderBase>(context, listen: false);
      final currentUserId = authProvider.currentUserId;
      final currentUserEmail = authProvider.userEmail;
      final currentUserName = authProvider.displayName;

      if (currentUserId == null) {
        setState(() {
          _errorMessage = "User not logged in. Please re-authenticate.";
          _isLoading = false;
        });
        return;
      }

      // Call AuthProvider's method to create family and update user profile
      await authProvider.createFamilyAndSetProfile(
        familyName: _familyNameController.text.trim(),
        familyDescription: 'Family created by ${currentUserName ?? 'user'}',
        creatorEmail: currentUserEmail ?? '',
      );

      // Check if family creation was successful and user profile updated
      if (authProvider.userFamilyId != null) {
        _logger.i(
          "Family '${_familyNameController.text.trim()}' created and user profile updated.",
        );
        if (mounted) {
          // No explicit navigation needed here. AuthWrapper will react to userFamilyId change.
          // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardScreen()));
        }
      } else {
        // This case should ideally be caught by AuthProvider's error messages
        setState(() {
          _errorMessage =
              authProvider.errorMessage ??
              "Failed to create family: Unknown error.";
        });
      }
    } catch (e, s) {
      _logger.e("Error creating family: $e", error: e, stackTrace: s);
      setState(() {
        _errorMessage =
            "An error occurred: ${e.toString().split('] ').last}"; // Extract Firebase error message
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Your Family')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Welcome! Let\'s set up your family.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _familyNameController,
                decoration: const InputDecoration(
                  labelText: 'Family Name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _createFamily,
                    child: const Text('Create Family'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        50,
                      ), // Make button full width
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
