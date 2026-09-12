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
///
/// Android is on real production IDs. iOS deliberately is not: no iOS app
/// has been registered in the AdMob console yet, so its production slots
/// stay empty and it keeps serving test ads.
/// TODO(admob-ios): register the iOS app in AdMob, then fill in the three
/// iOS production values below and replace the test `GADApplicationIdentifier`
/// in ios/Runner/Info.plist.
abstract final class AdUnitIds {
  // The Android app ID is duplicated in
  // android/app/src/main/AndroidManifest.xml
  // (com.google.android.gms.ads.APPLICATION_ID) — the SDK reads it from the
  // manifest, not from here. Keep the two in sync: production ad units do
  // not fill against a test app ID.
  static const _productionAndroidAppId =
      'ca-app-pub-6564803074312178~3353682332';
  static const _productionIosAppId = '';

  static const _testAndroidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const _testIosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const _productionAndroidBannerUnitId =
      'ca-app-pub-6564803074312178/9881959480';
  static const _productionIosBannerUnitId = '';

  static const _testAndroidBannerUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const _testIosBannerUnitId = 'ca-app-pub-3940256099942544/2934735716';

  static const _productionAndroidInterstitialUnitId =
      'ca-app-pub-6564803074312178/5321188942';
  static const _productionIosInterstitialUnitId = '';

  static const _testAndroidInterstitialUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testIosInterstitialUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  static String get appId {
    final production = Platform.isIOS
        ? _productionIosAppId
        : _productionAndroidAppId;
    if (production.isNotEmpty) return production;
    return Platform.isIOS ? _testIosAppId : _testAndroidAppId;
  }

  static String get bannerUnitId {
    final production = Platform.isIOS
        ? _productionIosBannerUnitId
        : _productionAndroidBannerUnitId;
    if (production.isNotEmpty) return production;
    return Platform.isIOS ? _testIosBannerUnitId : _testAndroidBannerUnitId;
  }

  static String get interstitialUnitId {
    final production = Platform.isIOS
        ? _productionIosInterstitialUnitId
        : _productionAndroidInterstitialUnitId;
    if (production.isNotEmpty) return production;
    return Platform.isIOS
        ? _testIosInterstitialUnitId
        : _testAndroidInterstitialUnitId;
  }

  /// True when *any* ad format is still falling back to a test ID on this
  /// platform — check before shipping a release build.
  static bool get isUsingTestIds =>
      bannerUnitId == _testAndroidBannerUnitId ||
      bannerUnitId == _testIosBannerUnitId ||
      interstitialUnitId == _testAndroidInterstitialUnitId ||
      interstitialUnitId == _testIosInterstitialUnitId;
}
