import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../pirith/domain/entities/pirith_entity.dart';

/// Sinhala title over its English name, centred — the player's heading.
///
/// Shared with the video screen; see [PlayerArtwork] for why these are
/// extracted rather than duplicated.
class PlayerTitleBlock extends StatelessWidget {
  const PlayerTitleBlock({required this.item, super.key});

  final PirithEntity item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          item.titleSinhala,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.sinhalaTitle(
            fontSize: 24,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (item.title.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.title,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.englishSerif(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}
