import 'package:firebase_auth/firebase_auth.dart';

import 'failure.dart';

/// Maps raw Firebase exceptions (Auth/Firestore/Storage all throw
/// [FirebaseException] or its subclasses) into the domain-level [Failure]
/// types declared in failure.dart. Data sources call this at the boundary
/// so nothing above the data layer ever sees a FirebaseException — see
/// docs/02_architecture.md.
Failure mapFirebaseError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'network-request-failed' => const NetworkFailure(),
      'user-not-found' => const NotFoundFailure(),
      _ => ServerFailure(error.message ?? error.code),
    };
  }

  if (error is FirebaseException) {
    return switch (error.code) {
      'unavailable' || 'deadline-exceeded' => const NetworkFailure(),
      'not-found' => const NotFoundFailure(),
      'permission-denied' || 'unauthenticated' => ServerFailure(
          error.message ?? error.code,
        ),
      _ => ServerFailure(error.message ?? error.code),
    };
  }

  return const UnknownFailure();
}
