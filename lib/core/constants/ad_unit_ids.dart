import 'dart:io' show Platform;

/// AdMob identifiers — see docs/07_monetization.md.
///
/// Uses Google's official public *test* app/ad-unit IDs
/// (https://developers.google.com/admob/ios/test-ads and
/// https://developers.google.com/admob/android/test-ads) whenever a real
/// production ID isn't configured below, so the app never accidentally
/// serves real ads (or gets the developer's AdMob account flagged for
/// invalid traffic) during development. Fill in the production values from
/// your own AdMob account before release — do not hardcode them anywhere
/// else in the app.
///
/// Android is on real production IDs. iOS deliberately is not: no iOS app
/// has been registered in the AdMob console yet, so its production slots
/// stay empty and it keeps serving test ads.
/// TODO(admob-ios): register the iOS app in AdMob, then fill in the production
/// values below and replace the test `GADApplicationIdentifier` in ios/Runner/Info.plist.
abstract final class AdUnitIds {
  // ===========================================================================
  // PRODUCTION ADMOB IDENTIFIERS
  // ===========================================================================

  // The Android app ID is duplicated in android/app/src/main/AndroidManifest.xml
  // (com.google.android.gms.ads.APPLICATION_ID) — the SDK reads it from the manifest.
  static const _productionAndroidAppId =
      'ca-app-pub-6564803074312178~3353682332';
  static const _productionIosAppId = '';

  static const _productionAndroidBannerUnitId =
      'ca-app-pub-6564803074312178/9881959480';
  static const _productionIosBannerUnitId = '';

  static const _productionAndroidInterstitialUnitId =
      'ca-app-pub-6564803074312178/5321188942';
  static const _productionIosInterstitialUnitId = '';

  static const _productionAndroidRewardedUnitId = '';
  static const _productionIosRewardedUnitId = '';

  static const _productionAndroidRewardedInterstitialUnitId = '';
  static const _productionIosRewardedInterstitialUnitId = '';

  static const _productionAndroidNativeAdvancedUnitId = '';
  static const _productionIosNativeAdvancedUnitId = '';

  static const _productionAndroidAppOpenUnitId = '';
  static const _productionIosAppOpenUnitId = '';

  // ===========================================================================
  // GOOGLE OFFICIAL TEST IDENTIFIERS (iOS)
  // https://developers.google.com/admob/ios/test-ads
  // ===========================================================================

  /// Official Google AdMob sample Application ID for iOS.
  static const testIosAppId = 'ca-app-pub-3940256099942544~1458002511';

  /// Official Google AdMob sample Banner Ad Unit ID for iOS.
  static const testIosBannerUnitId = 'ca-app-pub-3940256099942544/2934735716';

  /// Official Google AdMob sample Interstitial Ad Unit ID for iOS.
  static const testIosInterstitialUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  /// Official Google AdMob sample Rewarded Ad Unit ID for iOS.
  static const testIosRewardedUnitId = 'ca-app-pub-3940256099942544/1712485313';

  /// Official Google AdMob sample Rewarded Interstitial Ad Unit ID for iOS.
  static const testIosRewardedInterstitialUnitId =
      'ca-app-pub-3940256099942544/6978759866';

  /// Official Google AdMob sample Native Advanced Ad Unit ID for iOS.
  static const testIosNativeAdvancedUnitId =
      'ca-app-pub-3940256099942544/3986624511';

  /// Official Google AdMob sample App Open Ad Unit ID for iOS.
  static const testIosAppOpenUnitId = 'ca-app-pub-3940256099942544/5575463023';

  // ===========================================================================
  // GOOGLE OFFICIAL TEST IDENTIFIERS (Android)
  // https://developers.google.com/admob/android/test-ads
  // ===========================================================================

  /// Official Google AdMob sample Application ID for Android.
  static const testAndroidAppId = 'ca-app-pub-3940256099942544~3347511713';

  /// Official Google AdMob sample Banner Ad Unit ID for Android.
  static const testAndroidBannerUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  /// Official Google AdMob sample Interstitial Ad Unit ID for Android.
  static const testAndroidInterstitialUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  /// Official Google AdMob sample Rewarded Ad Unit ID for Android.
  static const testAndroidRewardedUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  /// Official Google AdMob sample Rewarded Interstitial Ad Unit ID for Android.
  static const testAndroidRewardedInterstitialUnitId =
      'ca-app-pub-3940256099942544/5354046379';

  /// Official Google AdMob sample Native Advanced Ad Unit ID for Android.
  static const testAndroidNativeAdvancedUnitId =
      'ca-app-pub-3940256099942544/2247696110';

  /// Official Google AdMob sample App Open Ad Unit ID for Android.
  static const testAndroidAppOpenUnitId =
      'ca-app-pub-3940256099942544/9257395921';

  // ===========================================================================
  // RESOLVED GETTERS (Platform-aware with test fallbacks)
  // ===========================================================================

  static String get appId {
    final production = Platform.isIOS
        ? _productionIosAppId
        : _productionAndroidAppId;
    if (production.isNotEmpty) return production;
    return Platform.isIOS ? testIosAppId : testAndroidAppId;
  }

  static String get bannerUnitId {
    final production = Platform.isIOS
        ? _productionIosBannerUnitId
        : _productionAndroidBannerUnitId;
    if (production.isNotEmpty) return production;
    return Platform.isIOS ? testIosBannerUnitId : testAndroidBannerUnitId;
  }

  static String get interstitialUnitId {
    final production = Platform.isIOS
        ? _productionIosInterstitialUnitId
        : _productionAndroidInterstitialUnitId;
    if (production.isNotEmpty) return production;
    return Platform.isIOS
        ? testIosInterstitialUnitId
        : testAndroidInterstitialUnitId;
  }

  static String get rewardedUnitId {
    final production = Platform.isIOS
        ? _productionIosRewardedUnitId
        : _productionAndroidRewardedUnitId;
    if (production.isNotEmpty) return production;
    return Platform.isIOS ? testIosRewardedUnitId : testAndroidRewardedUnitId;
  }

  static String get rewardedInterstitialUnitId {
    final production = Platform.isIOS
        ? _productionIosRewardedInterstitialUnitId
        : _productionAndroidRewardedInterstitialUnitId;
    if (production.isNotEmpty) return production;
    return Platform.isIOS
        ? testIosRewardedInterstitialUnitId
        : testAndroidRewardedInterstitialUnitId;
  }

  static String get nativeAdvancedUnitId {
    final production = Platform.isIOS
        ? _productionIosNativeAdvancedUnitId
        : _productionAndroidNativeAdvancedUnitId;
    if (production.isNotEmpty) return production;
    return Platform.isIOS
        ? testIosNativeAdvancedUnitId
        : testAndroidNativeAdvancedUnitId;
  }

  static String get appOpenUnitId {
    final production = Platform.isIOS
        ? _productionIosAppOpenUnitId
        : _productionAndroidAppOpenUnitId;
    if (production.isNotEmpty) return production;
    return Platform.isIOS ? testIosAppOpenUnitId : testAndroidAppOpenUnitId;
  }

  /// True when *any* active ad format is still falling back to a test ID on this
  /// platform — check before shipping a release build.
  static bool get isUsingTestIds =>
      bannerUnitId == testAndroidBannerUnitId ||
      bannerUnitId == testIosBannerUnitId ||
      interstitialUnitId == testAndroidInterstitialUnitId ||
      interstitialUnitId == testIosInterstitialUnitId;
}
