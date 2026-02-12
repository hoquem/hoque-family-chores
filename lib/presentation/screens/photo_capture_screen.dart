import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/photo_preview_widget.dart';
import '../providers/riverpod/photo_completion_notifier.dart';
import '../../domain/entities/task.dart';

/// Screen for capturing photo proof of task completion
class PhotoCaptureScreen extends ConsumerStatefulWidget {
  final Task task;

  const PhotoCaptureScreen({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends ConsumerState<PhotoCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _capturedPhoto;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check permissions and open camera immediately when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndOpenCamera();
    });
  }

  Future<void> _checkPermissionsAndOpenCamera() async {
    final status = await Permission.camera.status;

    if (status.isDenied) {
      final result = await Permission.camera.request();
      if (result.isDenied) {
        _showPermissionDialog();
        return;
      }
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDialog();
      return;
    }

    await _openCamera();
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Camera Access Required'),
        content: const Text(
          'We need camera access to capture your awesome work! 📸\n\n'
          'Please grant camera permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Also exit photo capture screen
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo != null) {
        setState(() {
          _capturedPhoto = File(photo.path);
        });
      } else {
        // User cancelled, go back
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _retakePhoto() async {
    setState(() {
      _capturedPhoto = null;
    });
    await _checkPermissionsAndOpenCamera();
  }

  Future<void> _usePhoto() async {
    if (_capturedPhoto == null || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the completion notifier
      final notifier = ref.read(photoCompletionNotifierProvider.notifier);

      // Complete task with photo
      final result = await notifier.completeTaskWithPhoto(
        task: widget.task,
        photo: _capturedPhoto!,
      );

      if (mounted) {
        if (result != null) {
          // Success - navigate to result screen
          Navigator.of(context).pushReplacementNamed(
            '/task-completion-result',
            arguments: {
              'task': widget.task,
              'completion': result,
            },
          );
        } else {
          // Error
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit photo. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Proof'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading your proof... 📤'),
                  SizedBox(height: 8),
                  Text('AI is checking your work... 🤖✨'),
                ],
              ),
            )
          : _capturedPhoto == null
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : PhotoPreviewWidget(
                  photo: _capturedPhoto!,
                  onRetake: _retakePhoto,
                  onUsePhoto: _isLoading ? null : _usePhoto,
                  taskTitle: widget.task.title,
                ),
    );
  }
}
