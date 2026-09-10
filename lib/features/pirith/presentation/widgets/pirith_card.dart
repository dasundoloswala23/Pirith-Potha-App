import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../downloads/domain/entities/download_entity.dart';
import '../../../downloads/presentation/bloc/download_bloc.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../../player/presentation/bloc/player_bloc.dart';
import '../../../premium/presentation/widgets/premium_badge.dart';
import '../../../premium/presentation/widgets/premium_gate.dart';
import '../../domain/entities/pirith_entity.dart';
import 'pirith_artwork.dart';

/// List row matching the reference `PirithCard`: artwork, Sinhala title +
/// English subtitle + duration, favorite/download/play actions. Tapping the
/// row opens details ([onTap]); the gold play button starts playback right
/// away via [PlayerBloc]; the download and favorite buttons reflect real
/// [DownloadBloc]/`FavoritesBloc` state.
class PirithCard extends StatelessWidget {
  const PirithCard({
    required this.item,
    required this.onTap,
    this.compact = false,
    super.key,
  });

  final PirithEntity item;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 10 : 12,
          ),
          child: Row(
            children: [
              PirithArtwork(
                pirithId: item.id,
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
                        Text(
                          item.durationLabel(),
                          style: theme.textTheme.labelSmall,
                        ),
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
                onTap: () {
                  if (ensurePremiumAccess(
                    context,
                    isPremiumItem: item.isPremium,
                  )) {
                    context.read<PlayerBloc>().add(PlayerPlayRequested(item));
                  }
                },
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.downloadDeleteConfirmTitle),
        content: Text(l10n.downloadDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<DownloadBloc>().add(DownloadDeleteRequested(item.id));
    }
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap});

  final VoidCallback onTap;

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
