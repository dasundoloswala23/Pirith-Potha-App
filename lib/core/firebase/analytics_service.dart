import 'package:firebase_analytics/firebase_analytics.dart';

/// Thin wrapper around [FirebaseAnalytics] so features log through a small,
/// typed surface instead of calling the SDK directly — keeps event names
/// consistent with docs/07_monetization.md and makes analytics easy to stub
/// in tests. Feature phases call these methods; none are wired up to real
/// user actions yet.
class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  Future<void> logPirithPlayed(String pirithId) =>
      _analytics.logEvent(name: 'pirith_played', parameters: {'pirith_id': pirithId});

  Future<void> logPirithDownloaded(String pirithId) => _analytics.logEvent(
        name: 'pirith_downloaded',
        parameters: {'pirith_id': pirithId},
      );

  Future<void> logPirithCompleted(String pirithId) => _analytics.logEvent(
        name: 'pirith_completed',
        parameters: {'pirith_id': pirithId},
      );

  Future<void> logFavoriteAdded(String pirithId) => _analytics.logEvent(
        name: 'favorite_added',
        parameters: {'pirith_id': pirithId},
      );

  Future<void> logSearchUsed(String query) =>
      _analytics.logEvent(name: 'search_used', parameters: {'query': query});

  Future<void> logPremiumClicked() => _analytics.logEvent(name: 'premium_clicked');
}
