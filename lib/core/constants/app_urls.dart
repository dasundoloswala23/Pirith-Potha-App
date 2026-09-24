/// Public web addresses the app links out to.
///
/// The privacy policy is a store requirement, not a nicety: Play Console and
/// App Store Connect both refuse a submission without a reachable URL, and
/// the same address must be entered in both listings. Its source lives in
/// `store/privacy-policy.html`.
abstract final class AppUrls {
  static const privacyPolicy = 'https://pithi-potha.web.app/privacy';

  static const youtubeChannel =
      'https://www.youtube.com/channel/UC4Ug5ybW6tJS3DKgtKJui3A';

  /// Android package id — used to build the Play Store listing URL.
  static const androidPackageId = 'com.pirith.pitithpotha';

  /// TODO(app-store-listing): placeholder. No App Store Connect listing
  /// exists yet (see docs/11_release_checklist.md) — this is the app's
  /// numeric App Store id once one does, e.g. from
  /// `https://apps.apple.com/app/id1234567890`. Both the update-available
  /// banner's "Update" link and `AppReviewService.promptFromSettings`'s
  /// `openStoreListing` fallback need it to do anything on iOS; until it's
  /// set, both quietly no-op there rather than open a broken link.
  static const appStoreId = '';

  static String get playStoreListing =>
      'https://play.google.com/store/apps/details?id=$androidPackageId';
}
