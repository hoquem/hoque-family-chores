import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feedback_service.g.dart';

/// The kind of feedback a user is sending. Kept small and enumerable so it can
/// be filtered in the console.
enum FeedbackType {
  general,
  bug,
  featureRequest;

  String get label => switch (this) {
        FeedbackType.general => 'General',
        FeedbackType.bug => 'Something is broken',
        FeedbackType.featureRequest => 'Feature request',
      };
}

/// Records user feedback in a Firestore `feedback` collection.
///
/// Append-only (see security rules) — read it in the Firebase console. Unlike
/// analytics this is NOT fire-and-forget: the user is told whether it sent, so
/// [submit] throws on failure for the caller to surface.
class FeedbackService {
  /// [firestore] is injected in tests; left null in the app and resolved lazily
  /// so constructing the provider never touches Firebase.
  FeedbackService([this._firestore]);

  final FirebaseFirestore? _firestore;

  Future<void> submit({
    required String message,
    required FeedbackType type,
    required String userId,
    String? familyId,
    required String appVersion,
  }) async {
    final db = _firestore ?? FirebaseFirestore.instance;
    await db.collection('feedback').add({
      'message': message.trim(),
      'type': type.name,
      'userId': userId,
      'familyId': familyId,
      'appVersion': appVersion,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

@Riverpod(keepAlive: true)
FeedbackService feedbackService(Ref ref) => FeedbackService();
