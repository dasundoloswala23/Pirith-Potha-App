import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/core/constants/ad_unit_ids.dart';

void main() {
  group('AdUnitIds iOS test IDs', () {
    test('all official iOS test ad unit IDs are present and valid format', () {
      expect(AdUnitIds.testIosAppId, 'ca-app-pub-3940256099942544~1458002511');
      expect(
        AdUnitIds.testIosBannerUnitId,
        'ca-app-pub-3940256099942544/2934735716',
      );
      expect(
        AdUnitIds.testIosInterstitialUnitId,
        'ca-app-pub-3940256099942544/4411468910',
      );
      expect(
        AdUnitIds.testIosRewardedUnitId,
        'ca-app-pub-3940256099942544/1712485313',
      );
      expect(
        AdUnitIds.testIosRewardedInterstitialUnitId,
        'ca-app-pub-3940256099942544/6978759866',
      );
      expect(
        AdUnitIds.testIosNativeAdvancedUnitId,
        'ca-app-pub-3940256099942544/3986624511',
      );
      expect(
        AdUnitIds.testIosAppOpenUnitId,
        'ca-app-pub-3940256099942544/5575463023',
      );
    });

    test(
      'all official Android test ad unit IDs are present and valid format',
      () {
        expect(
          AdUnitIds.testAndroidAppId,
          'ca-app-pub-3940256099942544~3347511713',
        );
        expect(
          AdUnitIds.testAndroidBannerUnitId,
          'ca-app-pub-3940256099942544/6300978111',
        );
        expect(
          AdUnitIds.testAndroidInterstitialUnitId,
          'ca-app-pub-3940256099942544/1033173712',
        );
        expect(
          AdUnitIds.testAndroidRewardedUnitId,
          'ca-app-pub-3940256099942544/5224354917',
        );
        expect(
          AdUnitIds.testAndroidRewardedInterstitialUnitId,
          'ca-app-pub-3940256099942544/5354046379',
        );
        expect(
          AdUnitIds.testAndroidNativeAdvancedUnitId,
          'ca-app-pub-3940256099942544/2247696110',
        );
        expect(
          AdUnitIds.testAndroidAppOpenUnitId,
          'ca-app-pub-3940256099942544/9257395921',
        );
      },
    );

    test('getters return valid ad unit IDs without throwing', () {
      expect(AdUnitIds.appId, isNotEmpty);
      expect(AdUnitIds.bannerUnitId, isNotEmpty);
      expect(AdUnitIds.interstitialUnitId, isNotEmpty);
      expect(AdUnitIds.rewardedUnitId, isNotEmpty);
      expect(AdUnitIds.rewardedInterstitialUnitId, isNotEmpty);
      expect(AdUnitIds.nativeAdvancedUnitId, isNotEmpty);
      expect(AdUnitIds.appOpenUnitId, isNotEmpty);
    });
  });
}
