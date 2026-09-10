import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/premium/domain/entities/premium_feature.dart';
import '../../features/premium/domain/repositories/premium_repository.dart';
import '../constants/ad_unit_ids.dart';
import '../errors/error_reporter.dart';
import 'ad_service.dart';

/// `google_mobile_ads` isn't available on web/desktop — every method here
/// is a safe no-op off Android/iOS rather than crashing at startup, so the
/// rest of the app (and its web build, used for quick verification) never
/// needs to know AdMob exists.
///
/// `_initialized` is the guard for that: it stays false off Android/iOS, and
/// every entry point checks it *before* touching [AdUnitIds], which reads
/// `dart:io Platform` and would throw on web.
class MobileAdsService implements AdService {
  MobileAdsService(this._premiumRepository);

  final PremiumRepository _premiumRepository;
  bool _initialized = false;

  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;
  bool _showingInterstitial = false;

  @override
  Future<void> initialize() async {
    if (kIsWeb ||
        !(defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  bool get isInitialized => _initialized;

  @override
  bool get adsEnabled =>
      !_premiumRepository.hasAccess(PremiumFeature.adsRemoved);

  @override
  void preloadInterstitial() {
    if (!_initialized || !adsEnabled) return;
    if (_loadingInterstitial || _interstitial != null) return;

    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdUnitIds.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          // A brand-new ad unit returns no-fill for up to an hour, and no-fill
          // is normal in general — log it, don't treat it as a failure.
          _loadingInterstitial = false;
          _interstitial = null;
          debugPrint('[ads] interstitial failed to load: $error');
        },
      ),
    );
  }

  @override
  Future<bool> maybeShowInterstitial() async {
    if (!_initialized || !adsEnabled || _showingInterstitial) return false;

    final ad = _interstitial;
    if (ad == null) {
      // Nothing ready — start one for next time rather than showing now.
      preloadInterstitial();
      return false;
    }

    _showingInterstitial = true;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showingInterstitial = false;
        preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _showingInterstitial = false;
        debugPrint('[ads] interstitial failed to show: $error');
        preloadInterstitial();
      },
    );

    try {
      await ad.show();
      return true;
    } catch (e, st) {
      _showingInterstitial = false;
      reportNonFatal(e, st, reason: 'Interstitial show threw');
      return false;
    }
  }
}
