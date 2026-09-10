import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/pirith_entity.dart';
import 'pirith_artwork.dart';

/// List row matching the reference `PirithCard`: artwork, Sinhala title +
/// English subtitle + duration, favorite/download/play actions. Favorite
/// and download aren't implemented until Phases 6-7, so those buttons show
/// a "coming soon" hint instead of silently doing nothing.
class PirithCard extends StatelessWidget {
  const PirithCard({
    required this.item,
    required this.artworkIndex,
    required this.onTap,
    this.compact = false,
    super.key,
  });

  final PirithEntity item;
  final int artworkIndex;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 10 : 12,
          ),
          child: Row(
            children: [
              PirithArtwork(
                index: artworkIndex,
                size: compact ? 44 : 56,
                radius: 10,
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
                    Text(item.durationLabel(), style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_outline),
                onPressed: () => _showComingSoon(context, l10n),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined),
                onPressed: () => _showComingSoon(context, l10n),
              ),
              _PlayButton(onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
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
        decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
        child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
      ),
    );
  }
}
