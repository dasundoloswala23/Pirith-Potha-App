import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../features/player/presentation/widgets/mini_player_bar.dart';

/// Bottom-navigation shell wrapping the five primary top-level destinations
/// (Home, Search, Downloads, Favorites, Profile), matching the approved UI
/// reference's tab order, with the persistent mini-player docked above the
/// nav bar. Used as the [StatefulShellRoute] branch container from the
/// router.
class HomeShell extends StatelessWidget {
  const HomeShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                icon: const Icon(Icons.grid_view_outlined),
                selectedIcon: const Icon(Icons.grid_view),
                label: l10n.navCategories,
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
