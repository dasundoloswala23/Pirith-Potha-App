/// Ad SDK abstraction — see docs/07_monetization.md. UI never calls
/// `google_mobile_ads` directly; only [MobileAdsService] (the data-layer
/// implementation) and the banner widget it hands out do.
abstract interface class AdService {
  Future<void> initialize();

  /// Whether ads should be shown at all right now. Always `true` in V1 —
  /// Phase 9 (Premium) wires this to real entitlement so premium users see
  /// no ads without any change needed here or in the banner widget.
  bool get adsEnabled;
}
