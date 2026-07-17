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
/// Nothing in this app uploaded a file on the live path before this service.
/// The one existing pipeline sat inside ``FirebaseTaskCompletionRepository``, a
/// layer that is dead and slated for deletion.
///
/// Its compression settings were copied here at first and **were wrong**: 1MB
/// cap, 1920px, two attempts. On a device that rejected a normal iPhone photo
/// outright. They had never been run, so nobody knew. Settings from unexecuted
/// code are guesses wearing a uniform.
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

  /// The largest photo we will upload. ``storage.rules`` refuses anything over
  /// 5MB, so this sits well inside that.
  ///
  /// This was 1MB, inherited from the dead ``TaskCompletion`` layer along with
  /// the compression settings. That number had never survived contact with a
  /// real photo — nothing ever ran that code — and on a device it rejected the
  /// after shot outright.
  static const int maxBytes = 2 * 1024 * 1024;

  /// Longest edge, after scaling.
  ///
  /// 1920 (also inherited) is far more than this needs: these photos are
  /// glanced at on a phone by a parent deciding whether a floor got mopped,
  /// never zoomed or printed. 1280 keeps a 12MP shot recognisable at roughly a
  /// fifth of the pixels, which is the difference between an upload that works
  /// on kitchen wifi and one that does not.
  static const int maxDimension = 1280;

  /// Quality steps, tried in order until one fits under [maxBytes].
  ///
  /// A ladder rather than two fixed attempts. The old code tried 85, then 70,
  /// then gave up — so a photo of a cluttered room, which is precisely what a
  /// "before" is, could fail with no recourse. 40 is visibly softer but still
  /// answers the only question being asked of it: is the floor clean now?
  static const List<int> qualitySteps = [85, 70, 55, 40];

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

  /// Compresses to under [maxBytes], stepping quality down until it fits.
  ///
  /// Returns null only if even the lowest step is too big, which for a 1280px
  /// JPEG means something is very wrong. Returning null rather than uploading
  /// an oversized blob keeps that failure loud.
  Future<Uint8List?> _compress(File photo) async {
    for (final quality in qualitySteps) {
      final bytes = await FlutterImageCompress.compressWithFile(
        photo.path,
        quality: quality,
        minWidth: maxDimension,
        minHeight: maxDimension,
      );
      // A null here is the plugin failing outright, not the photo being too
      // big — retrying at a lower quality would not help.
      if (bytes == null) return null;
      if (bytes.length <= maxBytes) return bytes;
    }
    return null;
  }
}
