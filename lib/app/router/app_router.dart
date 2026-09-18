import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/ads/player_exit_ad_observer.dart';
import '../../core/constants/app_route_paths.dart';
import '../../features/downloads/presentation/pages/downloads_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/history/presentation/pages/recently_played_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/pirith/presentation/pages/categories_page.dart';
import '../../features/pirith/presentation/pages/category_pirith_list_page.dart';
import '../../features/pirith/presentation/pages/pirith_details_page.dart';
import '../../features/pirith/presentation/pages/pirith_list_page.dart';
import '../../features/player/presentation/pages/player_page.dart';
import '../../features/player/presentation/pages/queue_page.dart';
import '../../features/player/presentation/pages/video_pirith_page.dart';
import '../../features/playlists/presentation/pages/playlist_details_page.dart';
import '../../features/playlists/presentation/pages/playlists_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../widgets/home_shell.dart';
import '../widgets/splash_page.dart';

/// App-wide route configuration. The five bottom-nav destinations are
/// branches of a [StatefulShellRoute] so each keeps its own navigation
/// stack; splash/details/player are pushed full-screen outside the shell.
///
/// [adObserver] is optional so widget tests can build the router without a
/// configured ad SDK.
GoRouter buildAppRouter({NavigatorObserver? adObserver}) {
  return GoRouter(
    initialLocation: AppRoutePaths.splash,
    observers: [?adObserver],
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
                    path: 'recently-played',
                    builder: (context, state) => const RecentlyPlayedPage(),
                  ),
                  // Favorites is no longer a bottom-nav destination (five
                  // tabs already), so it's reached from Home and Settings.
                  GoRoute(
                    path: 'favorites',
                    builder: (context, state) => const FavoritesPage(),
                  ),
                  // Categories lost its bottom-nav slot to Playlists, so it
                  // lives under Home, reached from Home's "See all".
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
                path: AppRoutePaths.pirithList,
                builder: (context, state) => const PirithListPage(),
                routes: [
                  GoRoute(
                    path: ':pirithId',
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
                path: AppRoutePaths.playlists,
                builder: (context, state) => const PlaylistsPage(),
                routes: [
                  GoRoute(
                    path: ':playlistId',
                    builder: (context, state) => PlaylistDetailsPage(
                      playlistId: state.pathParameters['playlistId']!,
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
                path: AppRoutePaths.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        // Named so PlayerExitAdObserver can recognise this route without
        // depending on the path string.
        name: PlayerExitAdObserver.playerRouteName,
        path: AppRoutePaths.player,
        builder: (context, state) => const PlayerPage(),
      ),
      GoRoute(
        path: AppRoutePaths.queue,
        builder: (context, state) => const QueuePage(),
      ),
      // Deliberately NOT named PlayerExitAdObserver.playerRouteName: an
      // interstitial firing as the user crosses to or from the YouTube app
      // is the worst possible placement for it.
      GoRoute(
        path: AppRoutePaths.videoPirith,
        builder: (context, state) => VideoPirithPage(
          pirithId: state.pathParameters['pirithId']!,
        ),
      ),
    ],
  );
}
