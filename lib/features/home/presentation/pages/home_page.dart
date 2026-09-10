import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_route_paths.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/pirith_mark.dart';
import '../../../pirith/domain/entities/pirith_entity.dart';
import '../../../pirith/presentation/bloc/catalogue_bloc.dart';
import '../../../pirith/presentation/widgets/category_card.dart';
import '../../../pirith/presentation/widgets/pirith_artwork.dart';
import '../../../pirith/presentation/widgets/pirith_card.dart';
import '../../../player/presentation/bloc/player_bloc.dart';
import '../widgets/social_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PirithMark(size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Text(l10n.homeTitle),
          ],
        ),
      ),
      body: BlocBuilder<CatalogueBloc, CatalogueState>(
        builder: (context, state) {
          return switch (state) {
            CatalogueLoading() || CatalogueInitial() =>
              const Center(child: CircularProgressIndicator()),
            CatalogueError() => _HomeError(
                onRetry: () =>
                    context.read<CatalogueBloc>().add(const CatalogueRefreshRequested()),
              ),
            CatalogueLoaded() => _HomeContent(state: state),
          };
        },
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.authErrorGeneric),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(l10n.actionRetry)),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.state});

  final CatalogueLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final featured = state.featured.firstOrNull;
    final popular = state.popular.take(6).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.push(AppRoutePaths.search),
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.searchHint,
                  enabled: false,
                ),
                child: const SizedBox(height: 20),
              ),
            ),
          ),
        ),
        if (featured != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _FeaturedCard(item: featured, artworkIndex: 0),
            ),
          ),
        if (state.categories.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: l10n.sectionCategories,
              seeAllLabel: l10n.actionSeeAll,
              onSeeAll: () => context.push(AppRoutePaths.categories),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 120,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: state.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final category = state.categories[index];
                  return CategoryCard(
                    category: category,
                    index: index,
                    count: state.forCategory(category.id).length,
                    onTap: () =>
                        context.push(AppRoutePaths.categoryDetailsFor(category.id)),
                  );
                },
              ),
            ),
          ),
        ],
        if (popular.isNotEmpty) ...[
          SliverToBoxAdapter(child: _SectionHeader(title: l10n.sectionPopular)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: popular.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = popular[index];
                return PirithCard(
                  item: item,
                  artworkIndex: index,
                  onTap: () => context.push(AppRoutePaths.pirithDetailsFor(item.id)),
                );
              },
            ),
          ),
        ],
        if (featured == null && popular.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PirithMark(
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.comingSoon),
                  ],
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SocialSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.seeAllLabel, this.onSeeAll});

  final String title;
  final String? seeAllLabel;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.sinhalaTitle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: Text(seeAllLabel!)),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.item, required this.artworkIndex});

  final PirithEntity item;
  final int artworkIndex;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        context.read<PlayerBloc>().add(PlayerPlayRequested(item));
        context.push(AppRoutePaths.player);
      },
      child: Container(
        height: 160,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PirithArtwork(index: artworkIndex, size: 400, radius: 0),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.titleSinhala,
                    style: AppTypography.sinhalaTitle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.title} · ${item.durationLabel()}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
