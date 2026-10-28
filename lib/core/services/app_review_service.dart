import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import '../constants/app_urls.dart';
import '../errors/error_reporter.dart';
import '../firebase/analytics_service.dart';

/// The manual "Rate this app" row in Settings.
///
/// The *automatic* review request lives in `ReviewPromptCoordinator`
/// (lib/features/app_review), driven by active usage. This stays a separate,
/// uncapped path: someone who explicitly asks to rate the app should always
/// see something happen.
///
/// Follows [NotificationPermission]'s shape: a static-only utility, never
/// registered with `getIt`, calls that never throw.
abstract final class AppReviewService {
  static AnalyticsService? _analytics;

  static void configure([AnalyticsService? analytics]) {
    _analytics = analytics;
  }

  @visibleForTesting
  static void resetForTest() {
    _analytics = null;
  }

  static Future<void> promptFromSettings() async {
    try {
      if (kIsWeb ||
          !(defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        unawaited(_analytics?.logReviewPromptTriggered('manual'));
        return;
      }
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
