import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/notification_repository.dart';

/// Use case for deleting notifications
class DeleteNotificationUseCase {
  final NotificationRepository _notificationRepository;

  DeleteNotificationUseCase(this._notificationRepository);

  /// Deletes a notification
  /// 
  /// [notificationId] - ID of the notification to delete
  /// 
  /// Returns [Unit] on success or [Failure] on error
  Future<Either<Failure, Unit>> call({
    required String notificationId,
  }) async {
    try {
      // Validate notification ID
      if (notificationId.trim().isEmpty) {
        return Left(ValidationFailure('Notification ID cannot be empty'));
      }

      // Delete the notification
      await _notificationRepository.deleteNotification(notificationId);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to delete notification: $e'));
    }
  }
} 