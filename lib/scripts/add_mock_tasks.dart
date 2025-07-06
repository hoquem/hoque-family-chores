import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'dart:async';

// lib/scripts/add_mock_tasks.dart
// This script adds mock tasks directly to Firestore for testing purposes.
// It does not use any legacy model files.

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  // Set your test familyId and (optionally) test userId
  const familyId = 'ef37e597-5e7a-46b0-a00a-62147cb29c8c';

  final tasks = [
    {
      'title': 'Take out the trash',
      'description': 'Take the trash bins to the curb before 8am.',
      'assigneeId': '',
      'points': 5,
      'status': 'available',
      'familyId': familyId,
      'dueDate': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 1)),
      ),
    },
    {
      'title': 'Wash the dishes',
      'description': 'Clean all dishes after dinner.',
      'assigneeId': '',
      'points': 3,
      'status': 'available',
      'familyId': familyId,
      'dueDate': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 2)),
      ),
    },
    {
      'title': 'Vacuum the living room',
      'description': 'Vacuum all carpets and floors in the living room.',
      'assigneeId': '',
      'points': 4,
      'status': 'available',
      'familyId': familyId,
      'dueDate': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 3)),
      ),
    },
    {
      'title': 'Feed the dog',
      'description': 'Feed the dog breakfast and dinner.',
      'assigneeId': '',
      'points': 2,
      'status': 'available',
      'familyId': familyId,
      'dueDate': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 12)),
      ),
    },
    {
      'title': 'Water the plants',
      'description': 'Water all indoor and outdoor plants.',
      'assigneeId': '',
      'points': 3,
      'status': 'available',
      'familyId': familyId,
      'dueDate': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 4)),
      ),
    },
  ];

  final batch = firestore.batch();
  final tasksCollection = firestore
      .collection('families')
      .doc(familyId)
      .collection('tasks');

  for (final task in tasks) {
    final docRef = tasksCollection.doc();
    batch.set(docRef, task);
  }

  await batch.commit();
  print('Mock tasks added to Firestore for familyId: $familyId');
}
