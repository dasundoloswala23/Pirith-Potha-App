import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ads/widgets/banner_ad_widget.dart';
import '../../core/l10n/bilingual.dart';
import '../../features/player/presentation/widgets/mini_player_bar.dart';

/// Bottom-navigation shell wrapping the five primary top-level destinations
/// — Home, Pirith, Playlists, Downloads, Settings — with the persistent
/// mini-player docked above the nav bar. Used as the [StatefulShellRoute]
/// branch container from the router.
///
/// Labels are the leading language only: a nav label has room for one line
/// at ~10sp, so the usual Sinhala-over-English pairing doesn't fit here.
/// Categories and Favorites are reached from Home rather than the nav bar;
/// five destinations is the Material maximum and these two are browse-level
/// entry points, not places users live.
class HomeShell extends StatelessWidget {
  const HomeShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = Bilingual.of(context).primary;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Above the mini player, not between it and the nav bar: the ad
          // needs content on one side, not interactive strips on both.
          // One widget here covers all five tabs.
          const BannerAdWidget(anchored: true),
          const MiniPlayerBar(),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: l10n.navHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book),
                label: l10n.navPirith,
              ),
              NavigationDestination(
                icon: const Icon(Icons.queue_music_outlined),
                selectedIcon: const Icon(Icons.queue_music),
                label: l10n.navPlaylists,
              ),
              NavigationDestination(
                icon: const Icon(Icons.download_outlined),
                selectedIcon: const Icon(Icons.download),
                label: l10n.navDownloads,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: l10n.navProfile,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
