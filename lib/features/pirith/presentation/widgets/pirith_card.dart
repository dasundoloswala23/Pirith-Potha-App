import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
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
import '../utils/open_pirith.dart';
import 'pirith_artwork.dart';

/// List row: artwork, Sinhala title + English subtitle + duration, and
/// favorite/download/play actions.
///
/// Tapping anywhere on the row starts playback and opens the player — one
/// tap to listen, rather than stopping at a details page and making the
/// reader tap again. The gold play button does the same thing and stays as
/// an explicit affordance. Download and favorite reflect real
/// [DownloadBloc]/`FavoritesBloc` state.
///
/// Long-pressing offers "add to playlist". The trailing edge already carries
/// three controls; a fourth would crush the title on a 360dp screen. Because
/// long-press advertises nothing about itself, the player and details
/// screens — which have room — also show an explicit labelled button.
class PirithCard extends StatelessWidget {
  const PirithCard({
    required this.item,
    this.compact = false,
    this.onPlay,
    super.key,
  });

  final PirithEntity item;
  final bool compact;

  /// Replaces "play this one Pirith" — a playlist or category passes a
  /// closure that plays the whole list from this row instead. The premium
  /// gate still runs first either way.
  final VoidCallback? onPlay;

  void _play(BuildContext context) => openPirith(context, item, onPlay: onPlay);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _play(context),
        // Only for items that can actually be queued.
        onLongPress: item.hasAudio
            ? () => showAddToPlaylistSheet(
                context,
                pirithId: item.id,
                pirithTitle: item.titleSinhala,
              )
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 10 : 12,
          ),
          child: Row(
            children: [
              PirithArtwork(
                pirithId: item.id,
                coverUrl: item.coverUrl,
                size: compact ? 44 : 56,
                radius: AppRadius.sm,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.titleSinhala,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sinhalaTitle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // A video has no duration to show, and "0:00" reads
                        // as a broken file rather than as a video.
                        if (item.hasAudio)
                          Text(
                            item.durationLabel(),
                            style: theme.textTheme.labelSmall,
                          )
                        else if (item.isVideoOnly)
                          const _VideoBadge(),
                        _OfflineBadge(pirithId: item.id),
                        if (item.isPremium) ...[
                          const SizedBox(width: 6),
                          const PremiumBadge(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              FavoriteButton(pirithId: item.id),
              _DownloadButton(item: item),
              _PlayButton(
                icon: item.isVideoOnly ? Icons.smart_display : Icons.play_arrow,
                onTap: () => _play(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "✓ Offline" next to the duration once a Pirith is downloaded, so the
/// list itself shows what will still play without a connection.
class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge({required this.pirithId});

  final String pirithId;

  @override
  Widget build(BuildContext context) {
    final isDownloaded = context.select<DownloadBloc, bool>((bloc) {
      final state = bloc.state;
      if (state is! DownloadsLoaded) return false;
      return state.statusFor(pirithId)?.status == DownloadStatus.downloaded;
    });
    if (!isDownloaded) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 12, color: AppColors.green),
          const SizedBox(width: 2),
          Text(
            l10n.labelOffline,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.green),
          ),
        ],
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({required this.item});

  final PirithEntity item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entry = context.select<DownloadBloc, DownloadEntity?>((bloc) {
      final state = bloc.state;
      return state is DownloadsLoaded ? state.statusFor(item.id) : null;
    });

    // Nothing to download, and nothing already downloaded to manage.
    if (!item.hasAudio && entry == null) return const SizedBox.shrink();

    switch (entry?.status) {
      case DownloadStatus.downloading:
        return IconButton(
          icon: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: entry!.progress,
            ),
          ),
          tooltip: l10n.actionCancel,
          onPressed: () => context.read<DownloadBloc>().add(
            DownloadCancelRequested(item.id),
          ),
        );
      case DownloadStatus.downloaded:
        return IconButton(
          icon: const Icon(Icons.download_done, color: AppColors.green),
          onPressed: () => _confirmDelete(context, l10n),
        );
      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.error_outline, color: AppColors.maroon),
          tooltip: l10n.downloadFailed,
          onPressed: () =>
              context.read<DownloadBloc>().add(DownloadRequested(item)),
        );
      case DownloadStatus.notDownloaded:
      case null:
        return IconButton(
          icon: const Icon(Icons.download_outlined),
          onPressed: () {
            if (ensurePremiumAccess(context, isPremiumItem: item.isPremium)) {
              context.read<DownloadBloc>().add(DownloadRequested(item));
            }
          },
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

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap, this.icon = Icons.play_arrow});

  final VoidCallback onTap;

  /// A video gets a screen glyph. The gold circle stays either way — one
  /// odd-coloured dot in a gold list reads as an error state.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.gold,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
      ),
    );
  }
}


/// Marks a Pirith that exists only as a video, in place of a duration.
class _VideoBadge extends StatelessWidget {
  const _VideoBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.smart_display_outlined,
          size: 12,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 2),
        Text(
          AppLocalizations.of(context).labelVideo,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
