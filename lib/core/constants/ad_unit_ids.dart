import 'dart:io' show Platform;

/// AdMob identifiers — see docs/07_monetization.md.
///
/// Uses Google's official public *test* app/ad-unit IDs
/// (https://developers.google.com/admob/android/test-ads) whenever a real
/// production ID isn't configured below, so the app never accidentally
/// serves real ads (or gets the developer's AdMob account flagged for
/// invalid traffic) during development. Fill in the production values from
/// your own AdMob account before release — do not hardcode them anywhere
/// else in the app.
abstract final class AdUnitIds {
  // TODO(admob-production): replace with real AdMob app IDs before release,
  // and reference them from android/app/src/main/AndroidManifest.xml
  // (com.google.android.gms.ads.APPLICATION_ID) and
  // ios/Runner/Info.plist (GADApplicationIdentifier) respectively.
  static const _productionAndroidAppId = '';
  static const _productionIosAppId = '';

  static const _testAndroidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const _testIosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const _productionAndroidBannerUnitId = '';
  static const _productionIosBannerUnitId = '';

  static const _testAndroidBannerUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testIosBannerUnitId = 'ca-app-pub-3940256099942544/2934735716';

  static String get appId {
    final production = Platform.isIOS ? _productionIosAppId : _productionAndroidAppId;
    if (production.isNotEmpty) return production;
    return Platform.isIOS ? _testIosAppId : _testAndroidAppId;
  }

  static String get bannerUnitId {
    final production =
        Platform.isIOS ? _productionIosBannerUnitId : _productionAndroidBannerUnitId;
    if (production.isNotEmpty) return production;
    return Platform.isIOS ? _testIosBannerUnitId : _testAndroidBannerUnitId;
  }

  /// True until real production ad unit IDs are filled in above — check
  /// this before shipping a release build.
  static bool get isUsingTestIds =>
      bannerUnitId == _testAndroidBannerUnitId || bannerUnitId == _testIosBannerUnitId;
}
