import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ads/widgets/banner_ad_widget.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../../../core/widgets/empty_state.dart';
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
      bottomNavigationBar: const BannerAdWidget(anchored: true),
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
                  Expanded(
                    child: EmptyState(
                      sinhalaTitle: bi.si.favoritesEmpty,
                      englishTitle: bi.en.favoritesEmpty,
                      subtitle: bi.si.favoritesEmptySubtitle,
                    ),
                  ),
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
                          return PirithCard(item: item);
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
