import 'package:go_router/go_router.dart';

import '../../core/constants/app_route_paths.dart';
import '../../features/downloads/presentation/pages/downloads_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/history/presentation/pages/recently_played_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/pirith/presentation/pages/categories_page.dart';
import '../../features/pirith/presentation/pages/category_pirith_list_page.dart';
import '../../features/pirith/presentation/pages/pirith_details_page.dart';
import '../../features/player/presentation/pages/player_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../widgets/home_shell.dart';
import '../widgets/splash_page.dart';

/// App-wide route configuration. The five bottom-nav destinations are
/// branches of a [StatefulShellRoute] so each keeps its own navigation
/// stack; splash/details/player are pushed full-screen outside the shell.
GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: AppRoutePaths.splash,
    routes: [
      GoRoute(
        path: AppRoutePaths.splash,
        builder: (context, state) => const SplashPage(),
      ),
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
                  GoRoute(
                    path: 'recently-played',
                    builder: (context, state) => const RecentlyPlayedPage(),
                  ),
                  GoRoute(
                    path: 'categories',
                    builder: (context, state) => const CategoriesPage(),
                    routes: [
                      GoRoute(
                        path: ':categoryId',
                        builder: (context, state) => CategoryPirithListPage(
                          categoryId: state.pathParameters['categoryId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.search,
                builder: (context, state) => const SearchPage(),
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
                builder: (context, state) => const ProfilePage(),
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
