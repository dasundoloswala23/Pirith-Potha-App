import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import 'pirith_mark.dart';

/// The "nothing here yet" block used by every list screen.
///
/// Four screens had grown their own copy — different mark sizes, different
/// spacing, and only one of them bilingual. This is the bilingual one, made
/// shared: Sinhala leads, English sits beneath it, and the subtitle explains
/// how to fill the screen.
///
/// It reads as calm rather than as an error — an empty favourites list is
/// not a failure.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.sinhalaTitle,
    required this.englishTitle,
    this.subtitle,
    this.action,
    super.key,
  });

  final String sinhalaTitle;
  final String englishTitle;
  final String? subtitle;

  /// Optional call to action — e.g. "create your first playlist".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;
    final action = this.action;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PirithMark(
              size: 56,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              sinhalaTitle,
              textAlign: TextAlign.center,
              style: AppTypography.sinhalaTitle(
                fontSize: 15,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              englishTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
