import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_route_paths.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/ads/widgets/banner_ad_widget.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', width: 28, height: 28),
            const SizedBox(width: 10),
            Text(l10n.homeTitle),
          ],
        ),
        actions: [
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
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
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
          if (featured != null) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(title: l10n.sectionFeatured),
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
                      title: l10n.sectionRecentlyPlayed,
                      seeAllLabel: l10n.actionSeeAll,
                      onSeeAll: () =>
                          context.push(AppRoutePaths.recentlyPlayed),
                    ),
                    SizedBox(
                      height: 96,
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
                title: l10n.sectionCategories,
                seeAllLabel: l10n.actionSeeAll,
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
              child: _SectionHeader(title: l10n.sectionPopular),
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
                  return PirithCard(
                    item: item,
                    onTap: () =>
                        context.push(AppRoutePaths.pirithDetailsFor(item.id)),
                  );
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
          const SliverToBoxAdapter(child: SocialSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.seeAllLabel, this.onSeeAll});

  final String title;
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
          // Interface text uses the app's English type ramp; the Sinhala
          // serif face is reserved for Pirith content itself.
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: Text(seeAllLabel!)),
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
        width: 72,
        child: Column(
          children: [
            PirithArtwork(pirithId: item.id, size: 64, radius: AppRadius.sm),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.titleSinhala,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
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
            PirithArtwork(pirithId: item.id, size: 400, radius: 0),
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
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.titleSinhala,
                    style: AppTypography.sinhalaTitle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
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
