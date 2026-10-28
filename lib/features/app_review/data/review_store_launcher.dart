import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_urls.dart';
import '../../../core/errors/error_reporter.dart';
import 'native_review_api.dart';

/// Contract for launching the native app store review / listing page.
abstract interface class ReviewStoreLauncher {
  Future<bool> openStore();
}

/// Production implementation of [ReviewStoreLauncher] supporting both Android and iOS.
///
/// Android:
/// 1. Tries `in_app_review.openStoreListing()`.
/// 2. Falls back to `market://details?id=...`.
/// 3. Falls back to `https://play.google.com/store/apps/details?id=...`.
///
/// iOS:
/// 1. Tries `in_app_review.openStoreListing(appStoreId: ...)`.
/// 2. Falls back to native App Store URI (`itms-apps://...`).
/// 3. Falls back to Web browser URL.
class DefaultReviewStoreLauncher implements ReviewStoreLauncher {
  DefaultReviewStoreLauncher({
    NativeReviewApi native = const InAppReviewApi(),
    TargetPlatform Function()? platform,
  }) : _native = native,
       _platform = platform ?? (() => defaultTargetPlatform);

  final NativeReviewApi _native;
  final TargetPlatform Function() _platform;

  @override
  Future<bool> openStore() async {
    final currentPlatform = _platform();

    try {
      await _native.openStoreListing();
      return true;
    } catch (error, stackTrace) {
      reportNonFatal(
        error,
        stackTrace,
        reason:
            'Native openStoreListing failed, attempting fallback URL launch',
      );
    }

    // Direct URL launch fallback if in_app_review was unavailable or threw
    try {
      if (currentPlatform == TargetPlatform.android) {
        return await _launchAndroidFallback();
      } else if (currentPlatform == TargetPlatform.iOS) {
        return await _launchIosFallback();
      }
    } catch (e, st) {
      reportNonFatal(e, st, reason: 'Store listing URL launch fallback failed');
    }

    return false;
  }

  Future<bool> _launchAndroidFallback() async {
    try {
      final marketUri = Uri.parse(
        'market://details?id=${AppUrls.androidPackageId}',
      );
      if (await canLaunchUrl(marketUri)) {
        final launched = await launchUrl(
          marketUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      }
    } catch (_) {}

    try {
      final webUri = Uri.parse(AppUrls.playStoreListing);
      if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  Future<bool> _launchIosFallback() async {
    final storeId = AppUrls.appStoreId;
    if (storeId.isEmpty) return false;

    try {
      final appStoreUri = Uri.parse(
        'itms-apps://itunes.apple.com/app/id$storeId?action=write-review',
      );
      if (await canLaunchUrl(appStoreUri)) {
        final launched = await launchUrl(
          appStoreUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      }
    } catch (_) {}

    try {
      final listing = AppUrls.appStoreListing;
      if (listing != null) {
        final webUri = Uri.parse(listing);
        if (await canLaunchUrl(webUri)) {
          return await launchUrl(webUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (_) {}
    return false;
  }
}
