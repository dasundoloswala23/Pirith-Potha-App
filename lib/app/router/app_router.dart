import 'package:go_router/go_router.dart';

import '../../core/constants/app_route_paths.dart';
import '../../core/l10n/locale_controller.dart';
import '../../features/downloads/presentation/pages/downloads_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/pirith/presentation/pages/pirith_details_page.dart';
import '../../features/player/presentation/pages/player_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../widgets/home_shell.dart';

/// App-wide route configuration. The four bottom-nav destinations are
/// branches of a [StatefulShellRoute] so each keeps its own navigation
/// stack; details/player are pushed on top full-screen.
GoRouter buildAppRouter({required LocaleController localeController}) {
  return GoRouter(
    initialLocation: AppRoutePaths.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.home,
                builder: (context, state) => const HomePage(),
                routes: [
                  GoRoute(
                    path: 'pirith/:pirithId',
                    builder: (context, state) => PirithDetailsPage(
                      pirithId: state.pathParameters['pirithId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.downloads,
                builder: (context, state) => const DownloadsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.favorites,
                builder: (context, state) => const FavoritesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.profile,
                builder: (context, state) =>
                    ProfilePage(localeController: localeController),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutePaths.player,
        builder: (context, state) => const PlayerPage(),
      ),
    ],
  );
}
