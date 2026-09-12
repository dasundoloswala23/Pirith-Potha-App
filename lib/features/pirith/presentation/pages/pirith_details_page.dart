import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_route_paths.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../downloads/domain/entities/download_entity.dart';
import '../../../downloads/presentation/bloc/download_bloc.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../../player/presentation/bloc/player_bloc.dart';
import '../../../playlists/presentation/widgets/add_to_playlist_sheet.dart';
import '../../../premium/presentation/widgets/premium_badge.dart';
import '../../../premium/presentation/widgets/premium_gate.dart';
import '../../domain/entities/pirith_entity.dart';
import '../widgets/catalogue_loaded_builder.dart';
import '../widgets/pirith_artwork.dart';

/// Real Pirith details, sourced from the already-loaded catalogue. Play/
/// Download are gated behind [ensurePremiumAccess] for premium-only
/// content (see docs/07_monetization.md).
class PirithDetailsPage extends StatelessWidget {
  const PirithDetailsPage({required this.pirithId, super.key});

  final String pirithId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: CatalogueLoadedBuilder(
        builder: (context, state) {
          final item = state.pirith.where((p) => p.id == pirithId).firstOrNull;
          if (item == null) {
            return Column(
              children: [
                AppBar(),
                Expanded(child: Center(child: Text(l10n.comingSoon))),
              ],
            );
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(pinned: true, title: const SizedBox.shrink()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      PirithArtwork(
                        pirithId: item.id,
                        coverUrl: item.coverUrl,
                        size: 160,
                        radius: AppRadius.lg,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        item.titleSinhala,
                        textAlign: TextAlign.center,
                        style: AppTypography.sinhalaTitle(
                          fontSize: 22,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${item.title} · ${item.durationLabel()}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (item.isPremium) ...[
                            const SizedBox(width: 6),
                            const PremiumBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Hidden while this Pirith is the one playing —
                          // the inline transport below takes over, and a
                          // button reading "Play" mid-playback just reads
                          // as broken.
                          if (!_isPlayingThis(context, item.id))
                            FilledButton.icon(
                              onPressed: () {
                                if (!ensurePremiumAccess(
                                  context,
                                  isPremiumItem: item.isPremium,
                                )) {
                                  return;
                                }
                                context.read<PlayerBloc>().add(
                                  PlayerPlayRequested(item),
                                );
                                context.push(AppRoutePaths.player);
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: Text(l10n.actionPlay),
                            ),
                          if (!_isPlayingThis(context, item.id))
                            const SizedBox(width: 12),
                          _DetailsDownloadButton(item: item),
                          const SizedBox(width: 12),
                          FavoriteButton(pirithId: item.id, outlined: true),
                          const SizedBox(width: 12),
                          // The explicit counterpart to the card's
                          // long-press, which nothing advertises.
                          IconButton.outlined(
                            tooltip: Bilingual.of(context).si.playlistAddTo,
                            icon: const Icon(Icons.playlist_add),
                            onPressed: () => showAddToPlaylistSheet(
                              context,
                              pirithId: item.id,
                              pirithTitle: item.titleSinhala,
                            ),
                          ),
                        ],
                      ),
                      _InlinePlayback(pirithId: item.id),
                      if (item.description.isNotEmpty ||
                          item.descriptionSinhala.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.pirithDescriptionLabel,
                            style: AppTypography.sinhalaTitle(
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.descriptionSinhala.isNotEmpty
                                ? item.descriptionSinhala
                                : item.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Whether the player is currently on this Pirith (playing or paused).
bool _isPlayingThis(BuildContext context, String pirithId) {
  final state = context.watch<PlayerBloc>().state;
  return state is PlayerActive && state.item.id == pirithId;
}

/// Playback position for *this* Pirith, shown inline once it's the one
/// playing — so the details page doubles as a player rather than making
/// the reader open a separate screen just to see where they are.
///
/// Renders nothing when a different Pirith (or nothing) is playing.
class _InlinePlayback extends StatelessWidget {
  const _InlinePlayback({required this.pirithId});

  final String pirithId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        if (state is! PlayerActive || state.item.id != pirithId) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final total = state.duration.inMilliseconds;
        final position = state.position.inMilliseconds.clamp(0, total).toDouble();

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: position,
                  max: total > 0 ? total.toDouble() : 1,
                  onChanged: (value) => context.read<PlayerBloc>().add(
                    PlayerSeekRequested(Duration(milliseconds: value.round())),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _clock(state.position),
                      style: theme.textTheme.labelSmall,
                    ),
                    Text(
                      _clock(state.duration),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              IconButton.filled(
                iconSize: 30,
                icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () => context.read<PlayerBloc>().add(
                  state.isPlaying
                      ? const PlayerPauseRequested()
                      : const PlayerResumeRequested(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

class _DetailsDownloadButton extends StatelessWidget {
  const _DetailsDownloadButton({required this.item});

  final PirithEntity item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entry = context.select<DownloadBloc, DownloadEntity?>((bloc) {
      final state = bloc.state;
      return state is DownloadsLoaded ? state.statusFor(item.id) : null;
    });

    switch (entry?.status) {
      case DownloadStatus.downloading:
        return OutlinedButton.icon(
          onPressed: () => context.read<DownloadBloc>().add(
            DownloadCancelRequested(item.id),
          ),
          icon: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: entry!.progress,
            ),
          ),
          label: Text(l10n.downloadInProgress),
        );
      case DownloadStatus.downloaded:
        return OutlinedButton.icon(
          onPressed: () => _confirmDelete(context, l10n),
          icon: const Icon(Icons.download_done),
          label: Text(l10n.downloadedLabel),
        );
      case DownloadStatus.failed:
        return OutlinedButton.icon(
          onPressed: () =>
              context.read<DownloadBloc>().add(DownloadRequested(item)),
          icon: const Icon(Icons.error_outline),
          label: Text(l10n.actionRetry),
        );
      case DownloadStatus.notDownloaded:
      case null:
        return OutlinedButton.icon(
          onPressed: () {
            if (ensurePremiumAccess(context, isPremiumItem: item.isPremium)) {
              context.read<DownloadBloc>().add(DownloadRequested(item));
            }
          },
          icon: const Icon(Icons.download_outlined),
          label: Text(l10n.actionDownload),
        );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final labels = Bilingual.read(context).primary;
    final confirmed = await confirmDestructive(
      context,
      title: labels.downloadDeleteConfirmTitle,
      body: labels.downloadDeleteConfirmBody,
      confirmLabel: labels.actionDelete,
    );
    if (confirmed && context.mounted) {
      context.read<DownloadBloc>().add(DownloadDeleteRequested(item.id));
    }
  }
}
