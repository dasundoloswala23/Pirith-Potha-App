import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/core/ads/player_exit_ad_observer.dart';

import '../../fakes/fake_ad_service.dart';

Route<void> _route(String? name) => PageRouteBuilder<void>(
  settings: RouteSettings(name: name),
  pageBuilder: (_, _, _) => const SizedBox.shrink(),
);

void main() {
  group('PlayerExitAdObserver', () {
    late FakeAdService ads;

    PlayerExitAdObserver observerWith({required bool playing}) =>
        PlayerExitAdObserver(ads: ads, isAudioPlaying: () => playing);

    setUp(() => ads = FakeAdService());

    testWidgets('preloads when the player opens', (tester) async {
      observerWith(playing: false).didPush(_route('player'), null);
      expect(ads.preloadCount, 1);
    });

    testWidgets('ignores routes other than the player', (tester) async {
      final observer = observerWith(playing: false);
      observer.didPush(_route('pirithDetails'), null);
      observer.didPop(_route('pirithDetails'), null);
      await tester.pump(const Duration(seconds: 1));

      expect(ads.preloadCount, 0);
      expect(ads.shownCount, 0);
    });

    testWidgets('shows an interstitial after leaving the player', (
      tester,
    ) async {
      observerWith(playing: false).didPop(_route('player'), null);
      // Nothing shows until the pop animation has had time to finish.
      expect(ads.shownCount, 0);

      await tester.pump(const Duration(seconds: 1));
      expect(ads.shownCount, 1);
    });

    testWidgets('does not interrupt playback that is still running', (
      tester,
    ) async {
      observerWith(playing: true).didPop(_route('player'), null);
      await tester.pump(const Duration(seconds: 1));

      expect(ads.shownCount, 0);
    });

    testWidgets('shows nothing when ads are disabled for premium users', (
      tester,
    ) async {
      ads.adsEnabled = false;
      observerWith(playing: false).didPop(_route('player'), null);
      await tester.pump(const Duration(seconds: 1));

      expect(ads.shownCount, 0);
    });

    testWidgets('treats a removed route the same as a pop', (tester) async {
      observerWith(playing: false).didRemove(_route('player'), null);
      await tester.pump(const Duration(seconds: 1));

      expect(ads.shownCount, 1);
    });
  });
}
