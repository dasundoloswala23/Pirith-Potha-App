import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_route_paths.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/pirith_mark.dart';
import '../../../pirith/presentation/widgets/catalogue_loaded_builder.dart';
import '../../../pirith/presentation/widgets/pirith_card.dart';
import '../bloc/favorites_bloc.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.favoritesTitle)),
      body: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, favoritesState) {
          if (favoritesState is! FavoritesLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (favoritesState.ids.isEmpty) {
            return _EmptyFavorites(l10n: l10n);
          }

          return CatalogueLoadedBuilder(
            builder: (context, catalogueState) {
              // Preserve favoritesState.ids order (most-recently-favorited
              // first) rather than catalogue order.
              final byId = {for (final p in catalogueState.pirith) p.id: p};
              final pirithItems = [
                for (final id in favoritesState.ids)
                  if (byId[id] != null) byId[id]!,
              ];

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: pirithItems.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = pirithItems[index];
                  return PirithCard(
                    item: item,
                    onTap: () =>
                        context.push(AppRoutePaths.pirithDetailsFor(item.id)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PirithMark(
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.favoritesEmpty,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.favoritesEmptySubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
