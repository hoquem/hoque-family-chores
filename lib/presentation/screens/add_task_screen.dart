import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/presentation/providers/task_list_provider.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:hoque_family_chores/presentation/providers/family_provider.dart';
import 'dart:async'; // Add this import for TimeoutException

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();
  DateTime? _dueDate;
  String? _selectedAssigneeId;
  bool _isLoading = false;
  final _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final taskListProvider = context.read<TaskListProvider>();
      final familyId = authProvider.userFamilyId;
      final creatorId = authProvider.currentUserId;

      if (familyId == null || creatorId == null) {
        throw Exception('User not properly authenticated');
      }

      _logger.i('Creating new task for family $familyId by user $creatorId');

      final task = Task(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        points: int.parse(_pointsController.text),
        difficulty: TaskDifficulty.easy, // Default to easy difficulty
        status: TaskStatus.available,
        familyId: familyId,
        assignedTo: _selectedAssigneeId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: _dueDate,
      );

      _logger.d('Task object created: ${task.toJson()}');

      // Add timeout to task creation
      await Future.any([
        taskListProvider.createTask(familyId: familyId, task: task),
        Future.delayed(const Duration(seconds: 10)).then((_) {
          throw TimeoutException('Task creation timed out after 10 seconds');
        }),
      ]);

      _logger.i('Task created successfully');

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on TimeoutException catch (e) {
      _logger.e('Task creation timed out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task creation timed out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, s) {
      _logger.e('Error creating task: $e', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating task: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFamilyMembers() async {
    final authProvider = context.read<AuthProvider>();
    final familyProvider = context.read<FamilyProvider>();
    final familyId = authProvider.userFamilyId;

    if (familyId != null) {
      await familyProvider.loadFamilyMembers(familyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final familyProvider = context.watch<FamilyProvider>();
    final familyMembers = familyProvider.familyMembers;
    final currentUser = authProvider.currentUser;

    _logger.i("Navigating to Add New Task screen.");

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Task')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pointsController,
              decoration: const InputDecoration(
                labelText: 'Points',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter points';
                }
                final points = int.tryParse(value);
                if (points == null || points <= 0) {
                  return 'Please enter a valid number of points';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Assign To (Optional)',
                border: OutlineInputBorder(),
              ),
              value: _selectedAssigneeId,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Leave Unassigned'),
                ),
                if (currentUser != null)
                  DropdownMenuItem<String>(
                    value: currentUser.member.id,
                    child: Text('Me (${currentUser.member.name})'),
                  ),
                ...familyMembers
                    .map((member) {
                      if (member.id == currentUser?.member.id) return null;
                      return DropdownMenuItem<String>(
                        value: member.id,
                        child: Text(member.name),
                      );
                    })
                    .whereType<DropdownMenuItem<String>>()
                    .toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAssigneeId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Due Date (Optional)',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _dueDate != null
                      ? DateFormat('MMM d, y').format(_dueDate!)
                      : 'Select a date',
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitTask,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Task'),
            ),
          ],
        ),
      ),
    );
  }
}
