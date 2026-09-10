import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Records a handled (non-fatal) error that the app recovered from — e.g. a
/// Firestore fetch that fell back to the on-disk cache. Without this, those
/// failures leave no trace at all and are undiagnosable in the field.
///
/// Crashlytics isn't available on every platform this project scaffolds (see
/// core/firebase/firebase_initializer.dart), so reporting is best-effort:
/// failing to record an error must never itself throw.
void reportNonFatal(Object error, StackTrace stack, {String? reason}) {
  debugPrint('[non-fatal]${reason == null ? '' : ' $reason:'} $error');
  try {
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      reason: reason,
      fatal: false,
    );
  } catch (_) {
    // Crashlytics unavailable on this platform — already logged above.
  }
}
