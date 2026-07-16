import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../core/error/failures.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/task_id.dart';

/// Which end of a before/after pair a photo is.
enum PhotoKind {
  before,
  after;

  String get slug => name;
}

/// Uploads and deletes task photos in Firebase Storage.
///
/// Nothing in this app uploaded a file on the live path before this service:
/// the one existing pipeline sits inside ``FirebaseTaskCompletionRepository``,
/// a layer that is dead and slated for deletion, so its compression settings
/// are carried over here rather than imported.
///
/// **Storage paths are family-scoped**::
///
///     families/{familyId}/tasks/{taskId}/{before|after}-{timestamp}.jpg
///
/// The old ``quest_photos/{taskId}/`` convention could not be secured per
/// family, and used pre-rename vocabulary. Nothing ever wrote to it, so there
/// is nothing to migrate. ``storage.rules`` scopes access to this shape; see
/// ``docs/superpowers/specs/2026-07-16-before-after-photos-design.md``.
class PhotoStorageService {
  PhotoStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Firebase Storage's own cap for a single photo. Beyond this the upload is
  /// refused rather than silently retried forever.
  static const int _maxBytes = 1024 * 1024;

  /// The Storage path for one photo.
  ///
  /// Pure and public because it is the **contract with ``storage.rules``**: the
  /// rules match on this exact shape, and if the two drift apart every upload
  /// is denied at runtime while the test suite stays green. Keeping it
  /// separable is what lets a test pin it without a platform channel.
  static String pathFor({
    required FamilyId familyId,
    required TaskId taskId,
    required PhotoKind kind,
    required int timestamp,
  }) =>
      'families/${familyId.value}/tasks/${taskId.value}/'
      '${kind.slug}-$timestamp.jpg';

  /// Compresses [photo] and uploads it, returning its download URL.
  ///
  /// [kind] distinguishes the before shot from the after so both can live
  /// under the same task without colliding.
  Future<Either<Failure, String>> upload({
    required File photo,
    required FamilyId familyId,
    required TaskId taskId,
    required PhotoKind kind,
  }) async {
    try {
      final bytes = await _compress(photo);
      if (bytes == null) {
        return Left(
          ServerFailure(
            'That photo is too large to send. Try again with a simpler scene.',
          ),
        );
      }

      final path = pathFor(
        familyId: familyId,
        taskId: taskId,
        kind: kind,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final snapshot = await _storage.ref().child(path).putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
      return Right(await snapshot.ref.getDownloadURL());
    } catch (e) {
      return Left(ServerFailure('Failed to upload photo: $e'));
    }
  }

  /// Deletes the blob behind [downloadUrl].
  ///
  /// Used when a child hands a started task back: the before photo must go
  /// with it, or the next child inherits a stranger's mess.
  Future<Either<Failure, void>> delete(String downloadUrl) async {
    try {
      await _storage.refFromURL(downloadUrl).delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete photo: $e'));
    }
  }

  /// Compresses to under [_maxBytes], or returns null if it cannot.
  ///
  /// Two passes, matching the settings the dead layer arrived at: quality 85
  /// first, then a harder 70 if the result is still too big. Returning null
  /// rather than uploading an oversized blob keeps the failure loud.
  Future<Uint8List?> _compress(File photo) async {
    final first = await FlutterImageCompress.compressWithFile(
      photo.path,
      quality: 85,
      minWidth: 1920,
      minHeight: 1920,
    );
    if (first == null) return null;
    if (first.length <= _maxBytes) return first;

    final second = await FlutterImageCompress.compressWithFile(
      photo.path,
      quality: 70,
      minWidth: 1920,
      minHeight: 1920,
    );
    if (second == null || second.length > _maxBytes) return null;
    return second;
  }
}
