import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/constants/app_route_paths.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../../../core/widgets/bilingual_text.dart';
import '../../../../core/widgets/pirith_mark.dart';
import '../../../pirith/presentation/widgets/catalogue_loaded_builder.dart';
import '../../../pirith/presentation/widgets/pirith_card.dart';
import '../bloc/favorites_bloc.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bi = Bilingual.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<FavoritesBloc, FavoritesState>(
          builder: (context, favoritesState) {
            if (favoritesState is! FavoritesLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final header = BilingualHeader(
              sinhala: bi.si.favoritesTitle,
              english: bi.en.favoritesTitle,
              englishSuffix: favoritesState.ids.isEmpty
                  ? null
                  : bi.en.favoritesSavedCount(favoritesState.ids.length),
            );

            if (favoritesState.ids.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  Expanded(child: _EmptyFavorites(l10n: l10n)),
                ],
              );
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        itemCount: pirithItems.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = pirithItems[index];
                          return PirithCard(
                            item: item,
                            onTap: () => context.push(
                              AppRoutePaths.pirithDetailsFor(item.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
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
