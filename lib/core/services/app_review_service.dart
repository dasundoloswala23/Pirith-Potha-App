import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_urls.dart';
import '../errors/error_reporter.dart';
import '../firebase/analytics_service.dart';

/// The native "rate this app" prompt (Play In-App Review on Android,
/// `SKStoreReviewController` on iOS via the `in_app_review` plugin), plus
/// the manual "Rate this app" row in Settings.
///
/// Follows [NotificationPermission]'s shape: a static-only utility, never
/// registered with `getIt`, calls that never throw. It differs in needing a
/// small amount of persistence (the once-per-version cap), so — unlike
/// [NotificationPermission], which needs no setup — it takes a one-time
/// [configure] call from `configureDependencies()` to receive the
/// [SharedPreferences] instance already read there.
abstract final class AppReviewService {
  static const _promptedVersionKey = 'review_prompted_version';

  static SharedPreferences? _prefs;
  static AnalyticsService? _analytics;

  static void configure(SharedPreferences prefs, [AnalyticsService? analytics]) {
    _prefs = prefs;
    _analytics = analytics;
  }

  @visibleForTesting
  static void resetForTest() {
    _prefs = null;
    _analytics = null;
  }

  /// Call after a genuinely positive moment — this app calls it when a
  /// chant finishes playing to completion, never on cold start.
  ///
  /// At most one attempt per app version, regardless of what happens next:
  /// neither store API reports whether its dialog actually rendered (both
  /// are quota-limited and may silently no-op by design), so "cap on
  /// attempt" is the only cap this can actually implement. Do not read
  /// "attempted" as "shown" — see docs/11_release_checklist.md.
  static Future<void> maybePromptAfterPositiveMoment() async {
    final prefs = _prefs;
    if (prefs == null) return;

    try {
      final version = (await PackageInfo.fromPlatform()).version;
      if (prefs.getString(_promptedVersionKey) == version) return;
      // Recorded before the attempt, not after: if requestReview() below
      // hangs or the app is killed mid-call, a second attempt this version
      // would only ever re-run the same quota-limited no-op, not show a
      // dialog it didn't already have a chance to show.
      await prefs.setString(_promptedVersionKey, version);

      if (!await InAppReview.instance.isAvailable()) return;
      await InAppReview.instance.requestReview();
      unawaited(_analytics?.logReviewPromptTriggered('automatic'));
    } catch (error, stackTrace) {
      reportNonFatal(error, stackTrace, reason: 'Review prompt failed');
    }
  }

  /// The Settings row: always attempts something, uncapped — a user who
  /// explicitly asks to rate the app should never see nothing happen.
  static Future<void> promptFromSettings() async {
    try {
      if (await InAppReview.instance.isAvailable()) {
        await InAppReview.instance.requestReview();
      } else {
        await InAppReview.instance.openStoreListing(
          appStoreId: AppUrls.appStoreId.isEmpty ? null : AppUrls.appStoreId,
        );
      }
      unawaited(_analytics?.logReviewPromptTriggered('manual'));
    } catch (error, stackTrace) {
      reportNonFatal(error, stackTrace, reason: 'Manual review prompt failed');
    }
  }
}
