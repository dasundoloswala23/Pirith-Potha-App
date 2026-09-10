import 'package:flutter/widgets.dart';

import 'ad_service.dart';

/// Shows an interstitial when the user leaves the player screen.
///
/// Placement rationale (see docs/07_monetization.md): this is a devotional
/// app, so an ad must never land on or interrupt the listening experience.
/// Two rules follow from that:
///
/// * The ad fires on the way *out* of the player, never on the way in.
/// * It is skipped entirely while audio is playing. A video interstitial
///   takes Android audio focus, which would duck or pause the chant
///   mid-Pirith and flip the media notification to paused with no user
///   action. Since the mini-player means many exits happen mid-playback,
///   this deliberately trades impressions away rather than interrupt.
///
/// Loading is started when the player is *opened*, giving the ad the length
/// of a listen to fill — an interstitial can only be shown if it was
/// preloaded.
class PlayerExitAdObserver extends NavigatorObserver {
  PlayerExitAdObserver({
    required AdService ads,
    required bool Function() isAudioPlaying,
  }) : _ads = ads,
       _isAudioPlaying = isAudioPlaying;

  /// Route name matched against `GoRoute(name: playerRouteName)`. Matching a
  /// name rather than a path keeps this from silently breaking if the path
  /// is ever changed.
  static const playerRouteName = 'player';

  final AdService _ads;
  final bool Function() _isAudioPlaying;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isPlayer(route)) _ads.preloadInterstitial();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _onLeftPlayer(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _onLeftPlayer(route);

  bool _isPlayer(Route<dynamic> route) =>
      route.settings.name == playerRouteName;

  void _onLeftPlayer(Route<dynamic> route) {
    if (!_isPlayer(route)) return;
    if (_isAudioPlaying()) return;

    // didPop fires at the *start* of the pop animation; showing immediately
    // flashes black or fails outright, so let the transition finish first.
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      // Null means the platform hasn't reported a state yet (normal early in
      // the app's life, and in tests) — only bail when we positively know
      // the app is backgrounded.
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
      // Re-checked because playback can resume during the pop animation.
      if (_isAudioPlaying()) return;
      _ads.maybeShowInterstitial();
    });
  }
}
