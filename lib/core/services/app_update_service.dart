import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

import '../errors/error_reporter.dart';

/// Android's Play Core flexible in-app update: checks for a newer published
/// version and downloads it in the background while the user keeps using
/// the app.
///
/// There is no equivalent API on iOS — Apple doesn't allow an app to update
/// itself — so [checkAndStartFlexibleUpdate] is a no-op there, same as
/// everywhere else in `lib/core/services/` that's Android-only
/// (see [NotificationPermission]).
///
/// Follows [NotificationPermission]'s shape: a static-only utility, never
/// registered with `getIt`, and its calls must never throw — a broken
/// update check must not stop the app from opening.
abstract final class AppUpdateService {
  /// Guards against re-checking on every rebuild; there's nothing to gain
  /// from asking Play twice in one session.
  static bool _checked = false;

  @visibleForTesting
  static void resetForTest() => _checked = false;

  /// `null` until a flexible download completes this session — a UI can
  /// listen for the one event it cares about ("downloaded, offer restart")
  /// without also having to model every intermediate download state.
  static Stream<void> get onFlexibleUpdateDownloaded => InAppUpdate
      .installUpdateListener
      .where((status) => status == InstallStatus.downloaded)
      .map((_) {});

  /// Starts a flexible update if one is available and Play allows it.
  ///
  /// Fire-and-forget: call from splash startup and move on. The actual
  /// "download finished, restart?" moment is surfaced later, from
  /// [onFlexibleUpdateDownloaded].
  static Future<void> checkAndStartFlexibleUpdate() async {
    if (_checked) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    _checked = true;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }
      if (!info.flexibleUpdateAllowed) return;

      await InAppUpdate.startFlexibleUpdate();
    } catch (error, stackTrace) {
      // Play Store not installed, no network, the user already has a
      // download in progress, etc. — all of these are routine, not bugs.
      reportNonFatal(error, stackTrace, reason: 'In-app update check failed');
    }
  }

  /// Installs the update [onFlexibleUpdateDownloaded] reported ready.
  static Future<void> completeUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (error, stackTrace) {
      reportNonFatal(error, stackTrace, reason: 'Failed to complete update');
    }
  }
}
