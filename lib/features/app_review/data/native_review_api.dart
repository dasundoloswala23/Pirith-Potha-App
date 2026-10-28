import 'package:in_app_review/in_app_review.dart';

import '../../../core/constants/app_urls.dart';

/// The three `in_app_review` calls the review feature uses, behind an
/// interface so tests can make them succeed or fail on demand — the real
/// plugin only throws `MissingPluginException` under `flutter test`.
abstract interface class NativeReviewApi {
  Future<bool> isAvailable();

  /// Quota-limited by both stores and may silently show nothing. Never
  /// bound to a button, never treated as "shown".
  Future<void> requestReview();

  /// Opens the store listing. Throws when it can't.
  Future<void> openStoreListing();
}

class InAppReviewApi implements NativeReviewApi {
  const InAppReviewApi();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();

  @override
  Future<void> openStoreListing() => InAppReview.instance.openStoreListing(
    appStoreId: AppUrls.appStoreId.isEmpty ? null : AppUrls.appStoreId,
  );
}
