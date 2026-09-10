import 'package:pitithpotha/core/ads/ad_service.dart';

class FakeAdService implements AdService {
  FakeAdService({this.adsEnabled = true, this.hasAdReady = true});

  @override
  bool adsEnabled;

  /// Whether a preloaded ad is available, so [maybeShowInterstitial] can
  /// report the same "nothing loaded yet" case the real service does.
  bool hasAdReady;

  int preloadCount = 0;
  int shownCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  void preloadInterstitial() => preloadCount++;

  @override
  Future<bool> maybeShowInterstitial() async {
    if (!adsEnabled || !hasAdReady) return false;
    shownCount++;
    return true;
  }
}
