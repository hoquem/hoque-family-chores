import 'package:in_app_review/in_app_review.dart';

/// The slice of `in_app_review` this app uses, behind an interface.
///
/// `InAppReview` is a singleton with a private constructor
/// (`InAppReview.instance`) — nothing to construct or fake for a test. This
/// interface is the seam: production code is wired to [InAppReviewRequester];
/// tests mock [ReviewRequester] instead.
abstract class ReviewRequester {
  /// Whether the platform can show its native review dialog right now —
  /// `SKStoreReviewController` on iOS, the Play In-App Review API on Android.
  Future<bool> isAvailable();

  /// Shows the native review dialog. The platform, not this call, decides
  /// whether it actually appears: both stores throttle this regardless of
  /// how often the app asks.
  Future<void> requestReview();
}

/// Wraps `InAppReview.instance`.
class InAppReviewRequester implements ReviewRequester {
  const InAppReviewRequester();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();
}
