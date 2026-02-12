import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/task_completion.dart';
import '../../domain/repositories/task_completion_repository.dart';
import '../../domain/value_objects/task_id.dart';
import '../../domain/value_objects/user_id.dart';

/// Firebase implementation of TaskCompletionRepository
class FirebaseTaskCompletionRepository implements TaskCompletionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseTaskCompletionRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<Either<Failure, String>> uploadPhoto({
    required File photo,
    required TaskId taskId,
    required UserId userId,
  }) async {
    try {
      // Compress image to max 1MB
      var compressedBytes = await FlutterImageCompress.compressWithFile(
        photo.path,
        quality: 85,
        minWidth: 1920,
        minHeight: 1920,
      );

      if (compressedBytes == null) {
        return Left(ServerFailure('Failed to compress image'));
      }

      // If still larger than 1MB, compress more aggressively
      const maxSize = 1024 * 1024; // 1MB
      if (compressedBytes.length > maxSize) {
        compressedBytes = await FlutterImageCompress.compressWithFile(
          photo.path,
          quality: 70,
          minWidth: 1920,
          minHeight: 1920,
        );
        
        if (compressedBytes == null || compressedBytes.length > maxSize) {
          return Left(ServerFailure(
            'Image too large. Please take a new photo with better lighting or a simpler scene.',
          ));
        }
      }

      // Upload to Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'quest_photos/${taskId.value}/$timestamp.jpg';

      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(
        compressedBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId.value,
            'taskId': taskId.value,
            'timestamp': timestamp.toString(),
            'originalSize': photo.lengthSync().toString(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return Right(downloadUrl);
    } catch (e) {
      return Left(ServerFailure('Failed to upload photo: $e'));
    }
  }

  @override
  Future<Either<Failure, TaskCompletion>> createCompletion({
    required TaskId taskId,
    required UserId userId,
    required String photoUrl,
    AiRating? aiRating,
  }) async {
    try {
      final docRef = _firestore.collection('questCompletions').doc();
      final completion = TaskCompletion(
        id: docRef.id,
        taskId: taskId,
        userId: userId,
        timestamp: DateTime.now(),
        photoUrl: photoUrl,
        status: TaskCompletionStatus.pendingApproval,
        aiRating: aiRating,
      );

      await docRef.set(_mapCompletionToFirestore(completion));
      return Right(completion);
    } catch (e) {
      return Left(ServerFailure('Failed to create completion: $e'));
    }
  }

  @override
  Future<Either<Failure, TaskCompletion>> getCompletion(
      String completionId) async {
    try {
      final doc =
          await _firestore.collection('questCompletions').doc(completionId).get();

      if (!doc.exists) {
        return Left(NotFoundFailure('Completion not found'));
      }

      return Right(_mapFirestoreToCompletion(doc.data()!, doc.id));
    } catch (e) {
      return Left(ServerFailure('Failed to get completion: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TaskCompletion>>> getTaskCompletions(
      TaskId taskId) async {
    try {
      final snapshot = await _firestore
          .collection('questCompletions')
          .where('taskId', isEqualTo: taskId.value)
          .get();

      final completions = snapshot.docs
          .map((doc) => _mapFirestoreToCompletion(doc.data(), doc.id))
          .toList();

      return Right(completions);
    } catch (e) {
      return Left(ServerFailure('Failed to get task completions: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TaskCompletion>>> getPendingCompletions() async {
    try {
      final snapshot = await _firestore
          .collection('questCompletions')
          .where('status', isEqualTo: TaskCompletionStatus.pendingApproval.name)
          .get();

      final completions = snapshot.docs
          .map((doc) => _mapFirestoreToCompletion(doc.data(), doc.id))
          .toList();

      return Right(completions);
    } catch (e) {
      return Left(ServerFailure('Failed to get pending completions: $e'));
    }
  }

  @override
  Future<Either<Failure, TaskCompletion>> updateWithApproval({
    required String completionId,
    required ParentApproval approval,
  }) async {
    try {
      final completionDoc =
          await _firestore.collection('questCompletions').doc(completionId).get();

      if (!completionDoc.exists) {
        return Left(NotFoundFailure('Completion not found'));
      }

      final completion = _mapFirestoreToCompletion(
        completionDoc.data()!,
        completionId,
      );

      final updatedCompletion = completion.copyWith(
        parentApproval: approval,
        status: approval.approved
            ? TaskCompletionStatus.approved
            : TaskCompletionStatus.rejected,
      );

      await _firestore
          .collection('questCompletions')
          .doc(completionId)
          .update(_mapCompletionToFirestore(updatedCompletion));

      return Right(updatedCompletion);
    } catch (e) {
      return Left(ServerFailure('Failed to update completion: $e'));
    }
  }

  /// Maps Firestore document data to domain TaskCompletion entity
  TaskCompletion _mapFirestoreToCompletion(
    Map<String, dynamic> data,
    String id,
  ) {
    return TaskCompletion(
      id: id,
      taskId: TaskId(data['taskId'] as String),
      userId: UserId(data['userId'] as String),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      photoUrl: data['photoUrl'] as String,
      status: TaskCompletionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TaskCompletionStatus.pendingApproval,
      ),
      aiRating: data['aiRating'] != null
          ? _mapFirestoreToAiRating(data['aiRating'] as Map<String, dynamic>)
          : null,
      parentApproval: data['parentApproval'] != null
          ? _mapFirestoreToParentApproval(
              data['parentApproval'] as Map<String, dynamic>)
          : null,
    );
  }

  AiRating _mapFirestoreToAiRating(Map<String, dynamic> data) {
    return AiRating(
      stars: data['stars'] as int,
      comment: data['comment'] as String,
      relevant: data['relevant'] as bool,
      confidence: data['confidence'] as String,
      contentWarning: data['contentWarning'] as bool? ?? false,
      modelVersion: data['modelVersion'] as String,
      analysisTimestamp: (data['analysisTimestamp'] as Timestamp).toDate(),
    );
  }

  ParentApproval _mapFirestoreToParentApproval(Map<String, dynamic> data) {
    return ParentApproval(
      parentId: UserId(data['parentId'] as String),
      approved: data['approved'] as bool,
      comment: data['comment'] as String?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  /// Maps domain TaskCompletion entity to Firestore document data
  Map<String, dynamic> _mapCompletionToFirestore(TaskCompletion completion) {
    return {
      'taskId': completion.taskId.value,
      'userId': completion.userId.value,
      'timestamp': Timestamp.fromDate(completion.timestamp),
      'photoUrl': completion.photoUrl,
      'status': completion.status.name,
      'aiRating': completion.aiRating != null
          ? _mapAiRatingToFirestore(completion.aiRating!)
          : null,
      'parentApproval': completion.parentApproval != null
          ? _mapParentApprovalToFirestore(completion.parentApproval!)
          : null,
    };
  }

  Map<String, dynamic> _mapAiRatingToFirestore(AiRating rating) {
    return {
      'stars': rating.stars,
      'comment': rating.comment,
      'relevant': rating.relevant,
      'confidence': rating.confidence,
      'contentWarning': rating.contentWarning,
      'modelVersion': rating.modelVersion,
      'analysisTimestamp': Timestamp.fromDate(rating.analysisTimestamp),
    };
  }

  Map<String, dynamic> _mapParentApprovalToFirestore(ParentApproval approval) {
    return {
      'parentId': approval.parentId.value,
      'approved': approval.approved,
      'comment': approval.comment,
      'timestamp': Timestamp.fromDate(approval.timestamp),
    };
  }
}
