import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../constants/ad_unit_ids.dart';
import '../ad_service.dart';

/// Display ad — a standard banner by default, or a 300x250 medium
/// rectangle via [mediumRectangle].
///
/// Placement is the caller's responsibility. Keep clear separation from
/// playback controls: an ad directly under a transport row invites
/// accidental taps, which AdMob treats as invalid traffic.
///
/// Renders nothing (not even a loading placeholder) on web/desktop, when
/// ads are disabled (see [AdService.adsEnabled], wired to Premium), or if
/// the ad fails to load, so a slow or blocked ad call never leaves a
/// broken-looking gap in the layout.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({this.mediumRectangle = false, super.key});

  /// 300x250 instead of the 320x50 banner.
  final bool mediumRectangle;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (kIsWeb ||
        !(defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }
    // Not registered outside a fully-configured app (e.g. widget tests
    // that don't call configureDependencies()) — skip rather than throw.
    if (!GetIt.instance.isRegistered<AdService>()) return;
    if (!GetIt.instance<AdService>().adsEnabled) return;

    final ad = BannerAd(
      adUnitId: AdUnitIds.bannerUnitId,
      size: widget.mediumRectangle ? AdSize.mediumRectangle : AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _bannerAd = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (ad == null) return const SizedBox.shrink();

    return Align(
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
