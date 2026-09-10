import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Screen header: the Sinhala name large, with the English one small and
/// gold beneath it — the pattern used on every top-level screen in the
/// approved design ("සැකසුම්" over "Settings").
///
/// [englishSuffix] carries the extra context some screens show inline with
/// the English line, e.g. "Downloads · 4 pirith · Offline ready".
class BilingualHeader extends StatelessWidget {
  const BilingualHeader({
    required this.sinhala,
    required this.english,
    this.englishSuffix,
    super.key,
  });

  final String sinhala;
  final String english;
  final String? englishSuffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sinhala,
            style: AppTypography.sinhalaTitle(
              fontSize: 20,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            englishSuffix == null ? english : '$english · $englishSuffix',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-line label where the Sinhala name leads and the English sits under
/// it — used for Pirith and category names in lists and cards.
class BilingualLabel extends StatelessWidget {
  const BilingualLabel({
    required this.sinhala,
    required this.english,
    this.sinhalaSize = 14,
    this.color,
    this.englishColor,
    this.maxLines = 1,
    super.key,
  });

  final String sinhala;
  final String english;
  final double sinhalaSize;
  final Color? color;
  final Color? englishColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          sinhala,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.sinhalaTitle(
            fontSize: sinhalaSize,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
        if (english.isNotEmpty)
          Text(
            english,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: englishColor ?? theme.colorScheme.primary,
            ),
          ),
      ],
    );
  }
}
