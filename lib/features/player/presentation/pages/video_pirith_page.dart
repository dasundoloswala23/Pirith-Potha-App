import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/ads/widgets/banner_ad_widget.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../../pirith/presentation/widgets/catalogue_loaded_builder.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/player_artwork.dart';
import '../widgets/player_title_block.dart';
import '../widgets/youtube_preview_card.dart';

/// A Pirith that exists only as a video: cover, title, favourite and the
/// YouTube card. No transport, no progress, no download, no sleep timer —
/// there is no audio for any of them to act on.
///
/// Deliberately **not** part of [PlayerPage]. Opening a video must leave any
/// playing chant alone, which means [PlayerBloc]'s state has to keep
/// describing that chant — so this screen cannot read its item from the
/// player and resolves it from the catalogue instead. Keeping the two
/// physically apart is what stops someone reaching for `state.item` here.
class VideoPirithPage extends StatelessWidget {
  const VideoPirithPage({required this.pirithId, super.key});

  final String pirithId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          l10n.videoScreenTitle.toUpperCase(),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
      // Routes outside the shell hide the app-wide mini player, and audio may
      // still be playing behind this screen — so it brings its own. It
      // self-hides when nothing is playing.
      bottomNavigationBar: const SafeArea(child: MiniPlayerBar()),
      body: CatalogueLoadedBuilder(
        builder: (context, catalogue) {
          final item = catalogue.pirith
              .where((p) => p.id == pirithId)
              .firstOrNull;

          // Unknown id, or an id that turns out to have audio: a deep link
          // must never render a player-shaped screen with no controls.
          if (item == null || !item.isVideoOnly) {
            return Center(child: Text(l10n.comingSoon));
          }

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Same sizing as the player, so the two screens are
                // indistinguishable above the fold.
                final coverWidth = constraints.maxWidth.clamp(
                  200.0,
                  constraints.maxHeight * 0.45 * 16 / 9,
                );
                final coverHeight = coverWidth * 9 / 16;

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        PlayerArtwork(
                          item: item,
                          width: coverWidth,
                          height: coverHeight,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        PlayerTitleBlock(item: item),
                        const SizedBox(height: AppSpacing.sm),
                        // Says out loud why there are no controls, so the
                        // screen reads as deliberate rather than broken.
                        Text(
                          Bilingual.of(context).primary.videoOnlyNote,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FavoriteButton(pirithId: item.id, outlined: true),
                        const SizedBox(height: AppSpacing.lg),
                        YouTubePreviewCard(youtubeUrl: item.youtubeUrl),
                        const SizedBox(height: AppSpacing.xl),
                        const BannerAdWidget(mediumRectangle: true),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
