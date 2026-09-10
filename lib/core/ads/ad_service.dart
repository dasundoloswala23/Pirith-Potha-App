/// Ad SDK abstraction — see docs/07_monetization.md. UI never calls
/// `google_mobile_ads` directly; only [MobileAdsService] (the data-layer
/// implementation) and the banner widget it hands out do.
abstract interface class AdService {
  Future<void> initialize();

  /// Whether ads should be shown at all right now — wired to real Premium
  /// entitlement, so premium users see none without the callers caring.
  bool get adsEnabled;

  /// Starts loading an interstitial if one isn't already loaded or loading.
  /// Fire-and-forget and safe to call repeatedly; an interstitial can only
  /// be shown if it was loaded in advance, so this runs well before
  /// [maybeShowInterstitial].
  void preloadInterstitial();

  /// Shows a preloaded interstitial if one is ready and ads are enabled.
  /// Returns whether an ad was actually shown — callers must tolerate
  /// `false`, which is the normal case when nothing has loaded yet.
  Future<bool> maybeShowInterstitial();
}
