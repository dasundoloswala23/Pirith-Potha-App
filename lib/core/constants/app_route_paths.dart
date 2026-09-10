/// Centralized route path constants for [GoRouter] configuration.
abstract final class AppRoutePaths {
  static const home = '/home';
  static const downloads = '/downloads';
  static const favorites = '/favorites';
  static const profile = '/profile';
  static const pirithDetails = '/pirith/:pirithId';
  static const player = '/player';

  static String pirithDetailsFor(String pirithId) => '/pirith/$pirithId';
}
