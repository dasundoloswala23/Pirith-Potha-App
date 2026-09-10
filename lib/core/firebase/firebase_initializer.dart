import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Initializes Firebase Core and wires uncaught Flutter/Dart errors into
/// Crashlytics. Crashlytics isn't available on every platform this project
/// happens to scaffold (e.g. Windows desktop) — failures to enable it are
/// swallowed rather than crashing app startup, since crash reporting itself
/// must never be what takes the app down.
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (_) {
    // Crashlytics unavailable on this platform — non-fatal, continue.
  }
}
