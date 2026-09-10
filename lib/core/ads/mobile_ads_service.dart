import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/premium/domain/entities/premium_feature.dart';
import '../../features/premium/domain/repositories/premium_repository.dart';
import 'ad_service.dart';

/// `google_mobile_ads` isn't available on web/desktop — every method here
/// is a safe no-op off Android/iOS rather than crashing at startup, so the
/// rest of the app (and its web build, used for quick verification) never
/// needs to know AdMob exists.
class MobileAdsService implements AdService {
  MobileAdsService(this._premiumRepository);

  final PremiumRepository _premiumRepository;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (kIsWeb || !(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  bool get isInitialized => _initialized;

  @override
  bool get adsEnabled => !_premiumRepository.hasAccess(PremiumFeature.adsRemoved);
}
