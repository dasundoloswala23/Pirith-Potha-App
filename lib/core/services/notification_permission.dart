import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../errors/error_reporter.dart';

/// Android 13+ notification permission for the playback notification.
///
/// `POST_NOTIFICATIONS` is declared in AndroidManifest.xml, but on API 33+
/// that only makes it *requestable* — until the user grants it, background
/// audio still plays with no notification, no lock-screen controls and no
/// Bluetooth transport UI. For an app whose whole point is listening with
/// the screen off, that reads as broken.
///
/// The permission is asked for at first playback rather than at launch: a
/// permission prompt on a cold start has no context, and Android only ever
/// shows the system dialog twice before silently denying it forever.
///
/// Platforms other than Android, and Android below 13, report granted —
/// there is nothing to request.
abstract final class NotificationPermission {
  static const _channel = MethodChannel(
    'com.pirith.pitithpotha/notification_permission',
  );

  /// Set once the prompt has been shown this session, so that starting a
  /// second Pirith doesn't ask again.
  static bool _asked = false;

  @visibleForTesting
  static void resetForTest() => _asked = false;

  static Future<bool> isGranted() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      return await _channel.invokeMethod<bool>('isGranted') ?? true;
    } on PlatformException catch (error, stackTrace) {
      reportNonFatal(error, stackTrace, reason: 'Notification permission check');
      return true;
    } on MissingPluginException {
      // Widget tests and any host without the channel registered.
      return true;
    }
  }

  /// Asks once per session. Never throws: failing to show the prompt must
  /// not interrupt playback, which is what the user actually asked for.
  static Future<void> requestIfNeeded() async {
    if (_asked) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    _asked = true;

    try {
      if (await _channel.invokeMethod<bool>('isGranted') ?? true) return;
      await _channel.invokeMethod<bool>('request');
    } on PlatformException catch (error, stackTrace) {
      reportNonFatal(error, stackTrace, reason: 'Notification permission request');
    } on MissingPluginException {
      // Nothing to do — see isGranted().
    }
  }
}
