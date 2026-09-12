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

  Future<void> logPlaylistCreated(String playlistId) => _analytics.logEvent(
        name: 'playlist_created',
        parameters: {'playlist_id': playlistId},
      );

  Future<void> logPlaylistDeleted(String playlistId) => _analytics.logEvent(
        name: 'playlist_deleted',
        parameters: {'playlist_id': playlistId},
      );

  Future<void> logPlaylistPlayed(String playlistId, int itemCount) =>
      _analytics.logEvent(
        name: 'playlist_played',
        parameters: {'playlist_id': playlistId, 'item_count': itemCount},
      );

  Future<void> logPlaylistShuffleStarted(String playlistId, int itemCount) =>
      _analytics.logEvent(
        name: 'playlist_shuffle_started',
        parameters: {'playlist_id': playlistId, 'item_count': itemCount},
      );

  Future<void> logPirithAddedToPlaylist(String playlistId, String pirithId) =>
      _analytics.logEvent(
        name: 'pirith_added_to_playlist',
        parameters: {'playlist_id': playlistId, 'pirith_id': pirithId},
      );

  Future<void> logPirithRemovedFromPlaylist(
    String playlistId,
    String pirithId,
  ) =>
      _analytics.logEvent(
        name: 'pirith_removed_from_playlist',
        parameters: {'playlist_id': playlistId, 'pirith_id': pirithId},
      );
}
