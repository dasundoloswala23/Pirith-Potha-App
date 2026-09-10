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
  static const categories = '/categories';
  static const categoryDetails = '/categories/:categoryId';
  static const downloads = '/downloads';
  static const profile = '/profile';
  static const player = '/player';

  static String pirithDetailsFor(String pirithId) => '/pirith/$pirithId';
  static String categoryDetailsFor(String categoryId) => '/categories/$categoryId';
}
