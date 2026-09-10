import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../l10n/bilingual.dart';

/// Style for the leading (large) line of a bilingual pair. Chosen by the
/// *language* of the text, not its position: Sinhala always gets the
/// Sinhala serif face, English the app's Latin ramp, so flipping the
/// leading language never puts Latin glyphs in a Sinhala serif.
TextStyle _leadStyle(BuildContext context, {required bool isSinhala, required double size}) {
  final theme = Theme.of(context);
  return isSinhala
      ? AppTypography.sinhalaTitle(fontSize: size, color: theme.colorScheme.onSurface)
      : theme.textTheme.titleMedium!.copyWith(
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        );
}

TextStyle _subStyle(BuildContext context, {required bool isSinhala}) {
  final theme = Theme.of(context);
  final color = theme.colorScheme.primary;
  return isSinhala
      ? AppTypography.sinhalaBody(fontSize: 12, color: color)
      : theme.textTheme.bodySmall!.copyWith(color: color);
}

/// Screen header: the leading language large, the other small and gold
/// beneath it — "සැකසුම්" over "Settings", or the reverse when English
/// leads.
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
    final bi = Bilingual.of(context);
    final englishLine = englishSuffix == null
        ? english
        : '$english · $englishSuffix';
    final (lead, sub) = bi.order(sinhala, englishLine);

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
          Text(lead, style: _leadStyle(context, isSinhala: bi.sinhalaFirst, size: 20)),
          Text(sub, style: _subStyle(context, isSinhala: !bi.sinhalaFirst)),
        ],
      ),
    );
  }
}

/// Two-line label where the leading language comes first and the other sits
/// under it — used for Pirith and category names in lists and cards.
class BilingualLabel extends StatelessWidget {
  const BilingualLabel({
    required this.sinhala,
    required this.english,
    this.sinhalaSize = 14,
    this.maxLines = 1,
    super.key,
  });

  final String sinhala;
  final String english;
  final double sinhalaSize;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final bi = Bilingual.of(context);
    final (lead, sub) = bi.order(sinhala, english);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          lead,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: _leadStyle(context, isSinhala: bi.sinhalaFirst, size: sinhalaSize),
        ),
        if (sub.isNotEmpty)
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _subStyle(context, isSinhala: !bi.sinhalaFirst),
          ),
      ],
    );
  }
}
