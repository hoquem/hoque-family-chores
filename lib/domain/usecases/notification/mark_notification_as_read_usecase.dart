import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/notification_repository.dart';

/// Use case for marking notifications as read
class MarkNotificationAsReadUseCase {
  final NotificationRepository _notificationRepository;

  MarkNotificationAsReadUseCase(this._notificationRepository);

  /// Marks a notification as read
  /// 
  /// [notificationId] - ID of the notification to mark as read
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

      // Mark the notification as read
      await _notificationRepository.markNotificationAsRead(notificationId);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to mark notification as read: $e'));
    }
  }
} 