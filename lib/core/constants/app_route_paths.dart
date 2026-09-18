/// Centralized route path constants for [GoRouter] configuration.
///
/// Pirith details sits under the `/pirith` branch so [pirithDetailsFor]
/// resolves against a real route — it previously produced `/pirith/<id>`
/// while the route itself was nested at `/home/pirith/:pirithId`.
abstract final class AppRoutePaths {
  static const splash = '/';
  static const home = '/home';
  static const recentlyPlayed = '/home/recently-played';
  static const favorites = '/home/favorites';
  static const pirithList = '/pirith';
  static const pirithDetails = '/pirith/:pirithId';
  // Categories moved under the Home branch when Playlists took the third
  // bottom-nav slot; it is reached from Home's "See all".
  static const categories = '/home/categories';
  static const categoryDetails = '/home/categories/:categoryId';
  static const playlists = '/playlists';
  static const playlistDetails = '/playlists/:playlistId';
  static const queue = '/queue';

  /// Video-only Pirith get their own screen rather than the player: opening
  /// one must not disturb audio that is already playing, so it cannot be
  /// driven by PlayerBloc's state.
  static const videoPirith = '/video/:pirithId';
  static const downloads = '/downloads';
  static const profile = '/profile';
  static const player = '/player';

  static String pirithDetailsFor(String pirithId) => '/pirith/$pirithId';
  static String categoryDetailsFor(String categoryId) =>
      '/home/categories/$categoryId';
  static String playlistDetailsFor(String playlistId) =>
      '/playlists/$playlistId';
  static String videoPirithFor(String pirithId) => '/video/$pirithId';
}
