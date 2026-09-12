import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_route_paths.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../../../core/ads/widgets/banner_ad_widget.dart';
import '../../../../core/widgets/bilingual_text.dart';
import '../../../../core/widgets/pirith_mark.dart';
import '../../../history/presentation/bloc/history_bloc.dart';
import '../../../pirith/domain/entities/pirith_entity.dart';
import '../../../pirith/presentation/bloc/catalogue_bloc.dart';
import '../../../pirith/presentation/widgets/category_card.dart';
import '../../../pirith/presentation/widgets/pirith_artwork.dart';
import '../../../pirith/presentation/widgets/pirith_card.dart';
import '../../../player/presentation/bloc/player_bloc.dart';
import '../../../pirith/presentation/widgets/catalogue_loaded_builder.dart';
import '../../../premium/presentation/widgets/premium_gate.dart';
import '../widgets/social_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bi = Bilingual.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', width: 32, height: 32),
            const SizedBox(width: AppSpacing.md),
            BilingualLabel(
              sinhala: bi.si.homeTitle,
              english: bi.en.homeTitle,
              sinhalaSize: 17,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            tooltip: l10n.favoritesTitle,
            onPressed: () => context.push(AppRoutePaths.favorites),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.sectionRecentlyPlayed,
            onPressed: () => context.push(AppRoutePaths.recentlyPlayed),
          ),
        ],
      ),
      body: CatalogueLoadedBuilder(
        builder: (context, state) => _HomeContent(state: state),
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
    final bi = Bilingual.of(context);
    final featured = state.featured.firstOrNull;
    final popular = state.popular.take(6).toList();

    return RefreshIndicator(
      onRefresh: () => _refreshCatalogue(context),
      child: CustomScrollView(
        // The empty state is shorter than the viewport, so without this the
        // list can't be overscrolled and the gesture never fires.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              // A tappable mock of a search field rather than a disabled
              // TextField: `enabled: false` suppresses the hint entirely, so
              // the bar rendered blank.
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: () => context.go(AppRoutePaths.pirithList),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 20,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${bi.si.navSearch} · ${bi.en.searchHint}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SocialSection()),
          if (featured != null) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: bi.si.sectionFeatured,
                englishTitle: bi.en.sectionFeatured,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _FeaturedCard(item: featured),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: BlocBuilder<HistoryBloc, HistoryState>(
              builder: (context, historyState) {
                if (historyState is! HistoryLoaded ||
                    historyState.entries.isEmpty) {
                  return const SizedBox.shrink();
                }
                final byId = {for (final p in state.pirith) p.id: p};
                final recent = [
                  for (final entry in historyState.entries)
                    if (byId[entry.pirithId] != null) byId[entry.pirithId]!,
                ].take(10).toList();
                if (recent.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: bi.si.sectionRecentlyPlayed,
                      englishTitle: bi.en.sectionRecentlyPlayed,
                      seeAllLabel: l10n.actionSeeAll,
                      onSeeAll: () =>
                          context.push(AppRoutePaths.recentlyPlayed),
                    ),
                    SizedBox(
                      height: 150,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: recent.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.md),
                        itemBuilder: (context, index) =>
                            _RecentTile(item: recent[index]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (state.categories.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: bi.si.sectionCategories,
                englishTitle: bi.en.sectionCategories,
                seeAllLabel: l10n.actionSeeAll,
                // Categories is nested under Home now, so this must push
                // onto the Home stack — a `go` would replace it and leave
                // the user without a back button.
                onSeeAll: () => context.push(AppRoutePaths.categories),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: state.categories.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final category = state.categories[index];
                    return CategoryCard(
                      category: category,
                      index: index,
                      count: state.forCategory(category.id).length,
                      onTap: () => context.push(
                        AppRoutePaths.categoryDetailsFor(category.id),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          if (popular.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: bi.si.sectionPopular,
                englishTitle: bi.en.sectionPopular,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              sliver: SliverList.separated(
                itemCount: popular.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final item = popular[index];
                  return PirithCard(item: item);
                },
              ),
            ),
          ],
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: BannerAdWidget(),
            ),
          ),
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
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.comingSoon),
                    ],
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ],
      ),
    );
  }
}

/// Re-fetches the catalogue and completes once the BLoC settles, so the
/// refresh indicator disappears at the right moment rather than instantly.
Future<void> _refreshCatalogue(BuildContext context) {
  final bloc = context.read<CatalogueBloc>();
  bloc.add(const CatalogueRefreshRequested());
  return bloc.stream
      .firstWhere((s) => s is CatalogueLoaded || s is CatalogueError)
      .timeout(const Duration(seconds: 20), onTimeout: () => bloc.state);
}

/// Sinhala section name on the left; on the right either a "See all" action
/// or, when there's nowhere to go, the English name of the same section —
/// the pattern from the approved design.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.englishTitle,
    this.seeAllLabel,
    this.onSeeAll,
  });

  final String title;
  final String englishTitle;
  final String? seeAllLabel;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (context) {
              final bi = Bilingual.of(context);
              final (lead, _) = bi.order(title, englishTitle);
              return Text(
                lead,
                style: bi.sinhalaFirst
                    ? AppTypography.sinhalaTitle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      )
                    : Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
              );
            },
          ),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: Text(seeAllLabel!))
          else
            Builder(
              builder: (context) {
                final bi = Bilingual.of(context);
                final (_, sub) = bi.order(title, englishTitle);
                return Text(
                  sub,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.item});

  final PirithEntity item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () {
        if (!ensurePremiumAccess(context, isPremiumItem: item.isPremium)) {
          return;
        }
        context.read<PlayerBloc>().add(PlayerPlayRequested(item));
        context.push(AppRoutePaths.player);
      },
      child: SizedBox(
        width: 96,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PirithArtwork(
              pirithId: item.id,
              coverUrl: item.coverUrl,
              size: 96,
              radius: AppRadius.md,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.titleSinhala,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sinhalaTitle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.item});

  final PirithEntity item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () {
        if (!ensurePremiumAccess(context, isPremiumItem: item.isPremium)) {
          return;
        }
        context.read<PlayerBloc>().add(PlayerPlayRequested(item));
        context.push(AppRoutePaths.player);
      },
      child: Container(
        height: 160,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PirithArtwork(
              pirithId: item.id,
              coverUrl: item.coverUrl,
              size: 400,
              radius: 0,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              top: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  AppLocalizations.of(context).labelFeatured.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.titleSinhala,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sinhalaTitle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.title} · ${item.durationLabel()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 26,
                    ),
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
