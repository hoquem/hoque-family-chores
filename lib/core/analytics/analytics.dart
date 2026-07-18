import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../utils/logger.dart';

part 'analytics.g.dart';

/// Master switch. Flip to false to stop all analytics writes (the kill-switch;
/// a Remote Config flag could drive this later).
const bool kAnalyticsEnabled = true;

/// The fixed vocabulary of things we measure. Question-driven: each event earns
/// its place by informing a decision. Do not add one without a question it
/// answers.
enum AnalyticsEventName {
  // Activation funnel — does the core chore loop work?
  signedIn,
  familyCreated,
  familyJoined,
  taskCreated,
  taskCompleted,
  taskApproved,
  rewardCreated,
  rewardClaimed,
  // Discovery / engagement.
  screenViewed,
  helpOpened,
}

/// Writes usage events to a Firestore `analyticsEvents` collection.
///
/// PRIVACY: children are users. Events carry the Firebase uid (pseudonymous)
/// and low-cardinality params only — NEVER a name, email, or free text. The
/// collection is append-only (security rules); it is read via BigQuery/Looker
/// Studio, never by the app.
///
/// Every write is fire-and-forget and swallows its own error (logged). This is
/// the one place a failure is deliberately tolerated: a dropped analytics event
/// must never cost a user anything or break a screen.
class Analytics {
  /// [firestore] is injected in tests; in the app it's left null and resolved
  /// lazily to [FirebaseFirestore.instance] inside [log] — so constructing this
  /// (and reading its provider) never touches Firebase and is safe in tests and
  /// before Firebase is ready.
  Analytics([this._firestore]);

  final FirebaseFirestore? _firestore;
  final AppLogger _logger = AppLogger();

  Future<void> log(
    AnalyticsEventName name, {
    required String userId,
    String? familyId,
    Map<String, Object?> params = const {},
  }) async {
    if (!kAnalyticsEnabled) return;
    try {
      final db = _firestore ?? FirebaseFirestore.instance;
      await db.collection('analyticsEvents').add({
        'name': name.name,
        'userId': userId,
        'familyId': familyId,
        'params': params,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Never rethrow — analytics must not affect the app.
      _logger.w('[Analytics] dropped ${name.name}: $e');
    }
  }
}

@Riverpod(keepAlive: true)
Analytics analytics(Ref ref) => Analytics();
