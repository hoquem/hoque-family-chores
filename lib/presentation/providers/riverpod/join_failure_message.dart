import 'package:hoque_family_chores/core/error/failures.dart';

/// What to put on screen when joining a family fails.
///
/// The domain writes its own failures for a person to read — "No family found
/// for that invite code" tells them exactly what to try next — so those go
/// through untouched. A [ServerFailure] is the opposite: it carries whatever
/// the SDK said, which is how
/// "[cloud_firestore/permission-denied] The caller does not have permission to
/// execute the specified operation" ended up in front of a child (TASK-499).
///
/// The technical text is not lost; the notifiers log it before calling this.
///
/// :param failure: the failure the join use case returned.
/// :returns: a sentence worth showing someone.
String joinFailureMessage(Failure failure) => failure is ServerFailure
    ? "Couldn't join that family just now. Check the code and try again — "
        'if it keeps happening, ask whoever invited you for a fresh one.'
    : failure.message;
